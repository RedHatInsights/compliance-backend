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

      def rule_group_for(ref_id:)
        @rule_group_lookup[ref_id]
      end

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
  let!(:system_group) do
    FactoryBot.create(:v2_rule_group, security_guide: security_guide, ref_id: 'xccdf_group_system')
  end
  let!(:auth_group) do
    FactoryBot.create(
      :v2_rule_group,
      security_guide: security_guide,
      ref_id: 'xccdf_group_authentication'
    )
  end

  let!(:value_definition) do
    FactoryBot.create(:v2_value_definition, security_guide: security_guide, ref_id: 'xccdf_value_password_complexity')
  end

  let(:rule_group_lookup) do
    {
      system_group.ref_id => system_group,
      auth_group.ref_id => auth_group
    }
  end

  let(:value_lookup) { { value_definition.ref_id => value_definition } }

  let(:updated_rule_parser) do
    OpenStruct.new(
      id: 'xccdf_rule_disable_root',
      title: 'Disable SSH root logins',
      description: 'Ensure PermitRootLogin is disabled',
      rationale: 'Reduce attack surface',
      severity: 'high',
      parent_id: system_group.ref_id,
      values: [value_definition.ref_id],
      identifier: OpenStruct.new(label: 'CCE-12345', href: 'https://example.com'),
      references: [OpenStruct.new(href: 'https://example.com/ref')]
    )
  end

  let(:new_rule_parser) do
    OpenStruct.new(
      id: 'xccdf_rule_configure_sudo',
      title: 'Configure sudo secure_path',
      description: 'Set secure path for sudo',
      rationale: 'Hardens sudo environment',
      severity: 'medium',
      parent_id: auth_group.ref_id,
      values: [],
      identifier: OpenStruct.new(label: 'CCE-55555'),
      references: []
    )
  end

  let(:op_rules) { [updated_rule_parser, new_rule_parser] }

  let!(:existing_rule) do
    FactoryBot.create(:v2_rule,
                      security_guide: security_guide,
                      rule_group: auth_group,
                      ref_id: updated_rule_parser.id,
                      description: 'Old description',
                      rationale: 'Outdated rationale',
                      severity: 'low',
                      precedence: 999,
                      identifier: { 'label' => 'OLD-CCE', 'href' => 'https://old.example.com' },
                      references: [{ 'href' => 'https://old-ref.example.com' }],
                      value_checks: [])
  end

  let!(:unrelated_rule) { FactoryBot.create(:v2_rule) }

  describe '#save_rules' do
    before { service.save_rules }

    it 'upserts all updatable attributes on existing rules' do
      rule = existing_rule.reload

      expect(rule.attributes.slice(
               'identifier', 'references', 'description', 'precedence',
               'rationale', 'rule_group_id', 'severity', 'value_checks'
             )).to eq(
               'identifier' => { 'label' => 'CCE-12345', 'href' => 'https://example.com' },
               'references' => [{ 'href' => 'https://example.com/ref' }],
               'description' => updated_rule_parser.description,
               'precedence' => op_rules.index(updated_rule_parser),
               'rationale' => updated_rule_parser.rationale,
               'rule_group_id' => system_group.id,
               'severity' => updated_rule_parser.severity,
               'value_checks' => [value_definition.id]
             )
    end

    it 'creates new rules and links them to the appropriate rule group' do
      created = V2::Rule.find_by(ref_id: new_rule_parser.id, security_guide: security_guide)

      expect(created).not_to be_nil
      expect(created.rule_group_id).to eq(auth_group.id)
      expect(created.identifier).to eq('label' => 'CCE-55555')
    end

    it 'does not change rules that belong to other guides' do
      expect { unrelated_rule.reload }.not_to raise_error
      expect(unrelated_rule.title).to eq(unrelated_rule.reload.title)
    end
  end
end
