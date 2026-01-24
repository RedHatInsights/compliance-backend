# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::RuleGroups do
  subject(:service) do
    Class.new do
      include Xccdf::RuleGroups

      def initialize(security_guide:, op_rule_groups:)
        @security_guide = security_guide
        @op_rule_groups = op_rule_groups
      end
    end.new(security_guide: security_guide, op_rule_groups: op_rule_groups)
  end

  let(:security_guide) { FactoryBot.create(:v2_security_guide) }

  let!(:parent_rg) do
    FactoryBot.create(
      :v2_rule_group,
      security_guide: security_guide,
      ref_id: 'xccdf_parent_rule_group',
      precedence: 1
    )
  end

  let(:op_parent_rg) do
    OpenStruct.new(
      id: parent_rg.ref_id,
      title: 'Updated title',
      description: 'Updated description',
      rationale: 'Updated rationale',
      parent_ids: []
    )
  end

  let(:op_child_rg) do
    OpenStruct.new(
      id: 'xccdf_child_rule_group',
      title: Faker::Lorem.sentence,
      description: Faker::Lorem.paragraph,
      rationale: Faker::Lorem.paragraph,
      parent_ids: [parent_rg.ref_id]
    )
  end

  let(:op_rule_groups) { [op_parent_rg, op_child_rg] }

  describe '#save_rule_groups' do
    it 'upserts the rule groups' do
      service.save_rule_groups

      expect(parent_rg.reload.attributes.slice('title', 'description', 'rationale', 'precedence', 'ancestry')).to eq(
        'title' => op_parent_rg.title,
        'description' => op_parent_rg.description,
        'rationale' => op_parent_rg.rationale,
        'precedence' => op_rule_groups.index(op_parent_rg),
        'ancestry' => ''
      )

      created = V2::RuleGroup.find_by(ref_id: op_child_rg.id, security_guide: security_guide)

      expect(created).not_to be_nil
      expect(created.attributes.slice('title', 'description', 'rationale', 'precedence', 'ancestry')).to eq(
        'title' => op_child_rg.title,
        'description' => op_child_rg.description,
        'rationale' => op_child_rg.rationale,
        'precedence' => op_rule_groups.index(op_child_rg),
        'ancestry' => parent_rg.id.to_s
      )
    end

    context 'having multiple levels of ancestry' do
      let(:grandparent_rg) do
        FactoryBot.create(
          :v2_rule_group,
          security_guide: security_guide,
          ref_id: 'xccdf_grandparent_rule_group',
          description: Faker::Lorem.paragraph,
          rationale: Faker::Lorem.paragraph,
          precedence: 0
        )
      end

      let(:op_grandparent_rg) do
        OpenStruct.new(
          id: grandparent_rg.ref_id,
          title: grandparent_rg.title,
          description: grandparent_rg.description,
          rationale: grandparent_rg.rationale,
          parent_ids: []
        )
      end

      let(:op_rule_groups) { [op_grandparent_rg, op_parent_rg, op_child_rg] }

      before do
        op_parent_rg.parent_ids = [op_grandparent_rg.id]
        op_child_rg.parent_ids = [op_grandparent_rg.id, op_parent_rg.id]
      end

      it 'constructs the ancestry column of children correctly' do
        service.save_rule_groups

        child_group = V2::RuleGroup.find_by(ref_id: op_child_rg.id, security_guide: security_guide)

        expect(child_group.ancestry).to eq([grandparent_rg.id, parent_rg.id].join('/'))
        expect(parent_rg.reload.ancestry).to eq(grandparent_rg.id.to_s)
      end

      it 'keeps root level groups without ancestry' do
        service.save_rule_groups

        expect(grandparent_rg.reload.ancestry).to be_blank
      end

      context 'when a child no longer declares any parents' do
        before do
          op_child_rg.parent_ids = []
        end

        it 'removes the stale ancestry entry' do
          service.save_rule_groups

          child_group = V2::RuleGroup.find_by(ref_id: op_child_rg.id, security_guide: security_guide)

          expect(child_group.ancestry).to be_blank
        end
      end
    end

    context 'having a preceding rule group' do
      let(:op_preceding_rg) do
        OpenStruct.new(
          id: preceding_rg.ref_id,
          title: preceding_rg.title,
          description: preceding_rg.description,
          rationale: preceding_rg.rationale,
          parent_ids: []
        )
      end

      let!(:preceding_rg) do
        FactoryBot.create(
          :v2_rule_group,
          security_guide: security_guide,
          ref_id: 'xccdf_preceding_rule_group',
          title: Faker::Lorem.sentence,
          description: Faker::Lorem.paragraph,
          rationale: Faker::Lorem.paragraph,
          precedence: 0
        )
      end

      let(:op_rule_groups) { [op_parent_rg, op_preceding_rg] }

      it 'changes the precedence of rule groups when needed' do
        expect do
          service.save_rule_groups
        end.to change { parent_rg.reload.precedence }.to(op_rule_groups.index(op_parent_rg))
           .and change { preceding_rg.reload.precedence }.to(op_rule_groups.index(op_preceding_rg))
      end
    end

    context 'when the import runs multiple times with the same data' do
      before do
        service.save_rule_groups
      end

      it 'does not create duplicate rule groups' do
        expect do
          service.save_rule_groups
        end.not_to change(V2::RuleGroup.where(security_guide: security_guide), :count).from(2)
      end

      it 'keeps existing ancestry relationships intact' do
        child_ancestry = V2::RuleGroup.find_by(ref_id: op_child_rg.id, security_guide: security_guide).ancestry

        expect do
          service.save_rule_groups
        end.not_to(change { child_ancestry })
      end
    end
  end
end
