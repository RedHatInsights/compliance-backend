# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::Rules do
  subject(:service) do
    Class.new do
      include Xccdf::Rules

      def initialize(security_guide:, op_rules:, rule_group_lookup:, value_lookup:)
        @security_guide = security_guide
        @op_rules = op_rules
        @rule_group_lookup = rule_group_lookup
        @value_lookup = value_lookup
      end

      private

      # NOTE: taken from `app/services/concerns/xccdf/rule_groups.rb`
      def rule_group_for(ref_id:)
        @rule_group_lookup[ref_id]
      end

      # NOTE: taken from `app/services/concerns/xccdf/value_definitions.rb`
      def value_definition_for(ref_id:)
        @value_lookup.fetch(ref_id)
      end
    end.new(
      security_guide: security_guide,
      op_rules: op_rules,
      rule_group_lookup: rule_group_lookup,
      value_lookup: value_lookup
    )
  end

  let(:security_guide) { FactoryBot.create(:v2_security_guide) }
  let(:rule_groups) { FactoryBot.create_list(:v2_rule_group, 2, security_guide: security_guide) }

  let!(:value_definition) do
    FactoryBot.create(:v2_value_definition, security_guide: security_guide, ref_id: 'xccdf_value_password_complexity')
  end

  let(:rule_group_lookup) do
    {
      rule_groups[0].ref_id => rule_groups[0],
      rule_groups[1].ref_id => rule_groups[1]
    }
  end

  let(:value_lookup) { { value_definition.ref_id => value_definition } }

  let(:op_rule_to_update) do
    OpenStruct.new(
      id: 'xccdf_rule_disable_root',
      title: 'Disable SSH root logins',
      description: 'Ensure PermitRootLogin is disabled',
      rationale: 'Reduce attack surface',
      severity: 'high',
      parent_id: rule_groups[0].ref_id,
      values: [value_definition.ref_id],
      identifier: OpenStruct.new(label: 'CCE-12345', href: 'https://example.com'),
      references: [OpenStruct.new(href: 'https://example.com/ref')]
    )
  end

  let(:op_new_rule) do
    OpenStruct.new(
      id: 'xccdf_rule_configure_sudo',
      title: 'Configure sudo secure_path',
      description: 'Set secure path for sudo',
      rationale: 'Hardens sudo environment',
      severity: 'medium',
      parent_id: rule_groups[1].ref_id,
      values: [],
      identifier: OpenStruct.new(label: 'CCE-55555'),
      references: []
    )
  end

  let(:op_rules) { [op_rule_to_update, op_new_rule] }

  let!(:existing_rule) do
    FactoryBot.create(
      :v2_rule,
      security_guide: security_guide,
      rule_group: rule_groups[1],
      ref_id: op_rule_to_update.id,
      description: 'Old description',
      rationale: 'Outdated rationale',
      severity: 'low',
      precedence: 999,
      identifier: { 'label' => 'OLD-CCE', 'href' => 'https://old.example.com' },
      references: [{ 'href' => 'https://old-ref.example.com' }],
      value_checks: []
    )
  end

  let!(:unrelated_rule) { FactoryBot.create(:v2_rule) }

  describe '#save_rules' do
    it 'updates all parsed rules that changed' do
      expect do
        service.save_profiles
      end.to change {
        V2::Rule.where(security_guide: security_guide).count
      }.from(1).to(op_rules.count)

      expect(existing_rule.reload.attributes.slice(
               'identifier', 'references', 'description', 'precedence',
               'rationale', 'rule_group_id', 'severity', 'value_checks'
             )).to eq(
               'identifier' => { 'label' => 'CCE-12345', 'href' => 'https://example.com' },
               'references' => [{ 'href' => 'https://example.com/ref' }],
               'description' => op_rule_to_update.description,
               'precedence' => op_rules.index(op_rule_to_update),
               'rationale' => op_rule_to_update.rationale,
               'rule_group_id' => rule_groups[0].id,
               'severity' => op_rule_to_update.severity,
               'value_checks' => [value_definition.id]
             )
    end

    it 'imports all parsed rules that are new' do
      created = V2::Rule.find_by(ref_id: op_new_rule.id, security_guide: security_guide)

      expect(created).not_to be_nil
      expect(created.rule_group_id).to eq(rule_groups[1].id)
      expect(created.identifier).to eq('label' => 'CCE-55555')
    end
  end

  describe '#rules' do
    let(:created_rule) { V2::Rule.find_by(ref_id: op_new_rule.id, security_guide: security_guide) }

    it 'returns all parsed rules' do
      expect(service.rules).to eq([existing_rule, created_rule])
    end
  end
end
