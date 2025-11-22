# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::RuleGroups do
  GroupParser = Struct.new(:id, :title, :description, :rationale, :parent_ids, keyword_init: true)

  subject(:service) do
    Class.new do
      include Xccdf::RuleGroups

      def initialize(security_guide:, op_rule_groups:)
        @security_guide = security_guide
        @op_rule_groups = op_rule_groups
      end
    end.new(security_guide: security_guide, op_rule_groups: op_rule_groups)
  end

  let(:security_guide) { create(:v2_security_guide) }

  let!(:parent_group_record) do
    create(:v2_rule_group,
           security_guide: security_guide,
           ref_id: 'xccdf_group_system',
           description: 'Legacy description',
           rationale: 'Legacy rationale',
           precedence: 5)
  end

  let(:parent_parser) do
    GroupParser.new(
      id: parent_group_record.ref_id,
      title: 'System',
      description: 'Updated description',
      rationale: 'Updated rationale',
      parent_ids: []
    )
  end

  let(:child_parser) do
    GroupParser.new(
      id: 'xccdf_group_authentication',
      title: 'Authentication',
      description: 'Handles authentication rules',
      rationale: 'Keep SSH secure',
      parent_ids: [parent_parser.id]
    )
  end

  let(:op_rule_groups) { [parent_parser, child_parser] }

  let!(:unrelated_group) { create(:v2_rule_group) }

  describe '#save_rule_groups' do
    before { service.save_rule_groups }

    it 'updates existing rule groups with parser attributes and precedence' do
      expect(parent_group_record.reload.description).to eq('Updated description')
      expect(parent_group_record.rationale).to eq('Updated rationale')
      expect(parent_group_record.precedence).to eq(0)
    end

    it 'creates new rule groups and stores ancestry derived from parser parents' do
      created = V2::RuleGroup.find_by(ref_id: child_parser.id, security_guide: security_guide)

      expect(created).not_to be_nil
      expect(created.precedence).to eq(1)
      expect(created.ancestry).to eq(parent_group_record.id.to_s)
    end

    it 'does not touch rule groups that belong to other guides' do
      expect { unrelated_group.reload }.not_to raise_error
    end
  end
end
