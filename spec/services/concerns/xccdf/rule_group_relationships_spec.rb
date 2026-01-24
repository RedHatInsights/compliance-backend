# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::RuleGroupRelationships do
  subject(:service) do
    Class.new do
      include Xccdf::RuleGroupRelationships

      def initialize(op_rules:, op_rule_groups:, rules:, rule_groups:)
        @op_rules = op_rules
        @op_rule_groups = op_rule_groups
        @rules = rules
        @rule_groups = rule_groups
      end

      private

      # NOTE: taken from `app/services/concerns/xccdf/rules.rb`
      def rule_for(ref_id:)
        @rules.find { |r| r.ref_id == ref_id }
      end

      # NOTE: taken from `app/services/concerns/xccdf/rule_groups.rb`
      def rule_group_for(ref_id:)
        @rule_groups.find { |rg| rg.ref_id == ref_id }
      end
    end.new(
      op_rules: op_rules,
      op_rule_groups: op_rule_groups,
      rules: rules,
      rule_groups: rule_groups
    )
  end

  let(:security_guide) { FactoryBot.create(:v2_security_guide) }

  let(:rules) { FactoryBot.create_list(:v2_rule, 3, security_guide: security_guide) }
  let(:rule_groups) { FactoryBot.create_list(:v2_rule_group, 3, security_guide: security_guide) }

  describe '#save_rule_group_relationships' do
    let!(:existing_relationship) do
      FactoryBot.create(
        :v2_rule_group_relationship,
        :for_rule_and_rule_requires,
        left: rules[0],
        right: rules[1]
      )
    end

    context 'with required and conflicting rules or rule groups' do
      let(:op_rule1) do
        OpenStruct.new(
          id: rules[0].ref_id,
          requires: [rules[1].ref_id],
          conflicts: [rule_groups[0].ref_id]
        )
      end

      let(:op_rule_group2) do
        OpenStruct.new(
          id: rule_groups[1].ref_id,
          requires: [rules[2].ref_id, rule_groups[2].ref_id],
          conflicts: []
        )
      end

      let(:op_rule3) do
        OpenStruct.new(
          id: rules[2].ref_id,
          requires: [],
          conflicts: [rule_groups[1].ref_id]
        )
      end

      let(:op_rules) { [op_rule1, op_rule3] }
      let(:op_rule_groups) { [op_rule_group2] }

      let(:stale_rule) { FactoryBot.create(:v2_rule, security_guide: security_guide) }
      let!(:stale_relationship) do
        FactoryBot.create(
          :v2_rule_group_relationship,
          :for_rule_and_rule_requires,
          left: rules[0],
          right: stale_rule
        )
      end

      it 'saves relationships between rules and rule groups' do
        expect { service.save_rule_group_relationships }.to change { V2::RuleGroupRelationship.count }.by(3)
      end

      it 'deletes all stale relationships' do
        service.save_rule_group_relationships
        expect { stale_relationship.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does not delete valid relationships' do
        service.save_rule_group_relationships
        expect { existing_relationship.reload }.to_not raise_error
      end
    end

    context 'when the import runs multiple times with the same data' do
      let(:op_rule1) do
        OpenStruct.new(
          id: rules[0].ref_id,
          requires: [rules[1].ref_id],
          conflicts: []
        )
      end

      let(:op_rules) { [op_rule1] }
      let(:op_rule_groups) { [] }

      it 'saves records only once' do
        expect do
          service.save_rule_group_relationships
        end.not_to(change { V2::RuleGroupRelationship.count })
      end
    end

    context 'when there are no conflicting or required rules or rule groups' do
      let(:op_rule1) do
        OpenStruct.new(
          id: rule1.ref_id,
          requires: [],
          conflicts: []
        )
      end

      let(:op_rule_group1) do
        OpenStruct.new(
          id: rule_group1.ref_id,
          requires: [],
          conflicts: []
        )
      end

      let(:op_rules) { [op_rule1] }
      let(:op_rule_groups) { [op_rule_group1] }

      it 'does not create any rule group relationships' do
        expect do
          service.save_rule_group_relationships
        end.not_to(change { V2::RuleGroupRelationship.count })
      end
    end
  end
end
