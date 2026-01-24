# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::Fixes do
  subject(:service) do
    Class.new do
      include Xccdf::Fixes

      def initialize(security_guide:, rules:)
        @security_guide = security_guide
        @rules = rules
      end
    end.new(security_guide: security_guide, rules: rules)
  end

  let(:security_guide) { FactoryBot.create(:v2_security_guide) }

  let(:rule_with_existing_fix) { FactoryBot.create(:v2_rule, security_guide: security_guide) }
  let(:op_fix_to_update) do
    OpenStruct.new(
      system: V2::Fix::ANSIBLE,
      strategy: 'configure',
      disruption: 'low',
      complexity: 'low',
      text: 'updated ansible remediation'
    )
  end

  let(:rule_with_new_fix) { FactoryBot.create(:v2_rule, security_guide: security_guide) }
  let(:new_op_fix) do
    OpenStruct.new(
      system: V2::Fix::SHELL,
      strategy: 'script',
      disruption: 'medium',
      complexity: 'medium',
      text: 'echo hardened > /etc/example'
    )
  end

  let(:rules) { [rule_with_existing_fix, rule_with_new_fix] }
  let!(:stale_fix_record) { FactoryBot.create(:fix, rule: rule_with_existing_fix, system: op_fix_to_update.system) }

  before do
    rule_with_existing_fix.op_source = instance_double('RuleOpSource', fixes: [op_fix_to_update])
    rule_with_new_fix.op_source = instance_double('RuleOpSource', fixes: [new_op_fix])
  end

  describe '#save_fixes' do
    let(:refreshed_fix) { V2::Fix.find_by(rule: rule_with_existing_fix, system: op_fix_to_update.system) }
    let(:created_fix) { V2::Fix.find_by(rule: rule_with_new_fix, system: new_op_fix.system) }

    it 'upserts parsed fixes' do
      expect do
        service.save_fixes
      end.to change {
        V2::Fix.where(rule_id: rules.map(&:id)).count
      }.from(1).to(2)

      expect(created_fix).not_to be_nil
      expect(created_fix.rule_id).to eq(rule_with_new_fix.id)
      expect(created_fix.attributes.slice('strategy', 'disruption', 'complexity', 'system', 'text')).to eq(
        'strategy' => new_op_fix.strategy,
        'disruption' => new_op_fix.disruption,
        'complexity' => new_op_fix.complexity,
        'system' => new_op_fix.system,
        'text' => new_op_fix.text
      )

      expect(refreshed_fix.id).to eq(stale_fix_record.id)
      expect(refreshed_fix.rule_id).to eq(rule_with_existing_fix.id)
      expect(refreshed_fix.attributes.slice('strategy', 'disruption', 'complexity', 'system', 'text')).to eq(
        'strategy' => op_fix_to_update.strategy,
        'disruption' => op_fix_to_update.disruption,
        'complexity' => op_fix_to_update.complexity,
        'system' => op_fix_to_update.system,
        'text' => op_fix_to_update.text
      )
    end
  end

  describe '#fixes' do
    it 'returns all the parsed fixes that were changed' do
      results = service.fixes

      refreshed_fix = results.find { |fix| fix.rule_id == rule_with_existing_fix.id }
      created_fix = results.find { |fix| fix.rule_id == rule_with_new_fix.id }

      expect(refreshed_fix.id).to eq(stale_fix_record.id)
      expect(refreshed_fix).to be_persisted
      expect(refreshed_fix.attributes.slice('strategy', 'disruption', 'complexity', 'system', 'text')).to eq(
        'strategy' => op_fix_to_update.strategy,
        'disruption' => op_fix_to_update.disruption,
        'complexity' => op_fix_to_update.complexity,
        'system' => op_fix_to_update.system,
        'text' => op_fix_to_update.text
      )

      expect(created_fix).not_to be_persisted
      expect(created_fix.rule_id).to eq(rule_with_new_fix.id)
      expect(created_fix.attributes.slice('strategy', 'disruption', 'complexity', 'system', 'text')).to eq(
        'strategy' => new_op_fix.strategy,
        'disruption' => new_op_fix.disruption,
        'complexity' => new_op_fix.complexity,
        'system' => new_op_fix.system,
        'text' => new_op_fix.text
      )
    end
  end
end
