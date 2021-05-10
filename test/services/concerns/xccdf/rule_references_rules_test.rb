# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rule_references'

# A class to test saving RuleReferencesRules from OpenscapParser
class RuleReferencesRulesTest < ActiveSupport::TestCase
  include Xccdf::RuleReferencesRules

  test 'only new rule references rules are saved' do
    @rules = FactoryBot.create_list(:rule, 2)
    @rule_references = FactoryBot.create_list(:rule_reference, 2)
    @op_rules = [
      OpenStruct.new(id: @rules.first.ref_id,
                     rule_references: [@rule_references.first])
    ]

    assert_difference('RuleReferencesRule.count', 1) do
      save_rule_references_rules
    end

    @new_rule_references_rules,
      @existing_rule_references_rules,
      @op_rule_references_rules = nil # un-cache it from ||=
    @op_rules = [
      OpenStruct.new(id: @rules.first.ref_id,
                     rule_references: [@rule_references.first]),
      OpenStruct.new(id: @rules.last.ref_id,
                     rule_references: [@rule_references.last])
    ]

    assert_difference('RuleReferencesRule.count', 1) do
      save_rule_references_rules
    end

    @new_rule_references_rules,
      @existing_rule_references_rules = nil # un-cache it from ||=

    assert_difference('RuleReferencesRule.count', 0) do
      save_rule_references_rules
    end
  end
end
