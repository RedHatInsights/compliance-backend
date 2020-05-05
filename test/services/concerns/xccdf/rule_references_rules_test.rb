# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rule_references'

# A class to test saving RuleReferencesRules from OpenscapParser
class RuleReferencesRulesTest < ActiveSupport::TestCase
  include Xccdf::RuleReferencesRules

  test 'only new rule references rules are saved' do
    @rules = [rules(:one), rules(:two)]
    @rule_references = [rule_references(:one), rule_references(:two)]
    @op_rules = [
      OpenStruct.new(id: rules(:one).ref_id,
                     rule_references: [rule_references(:one)])
    ]

    assert_difference('RuleReferencesRule.count', 1) do
      save_rule_references_rules
    end

    @rule_references_rules = nil # un-cache it from ||=
    @op_rules = [
      OpenStruct.new(id: rules(:one).ref_id,
                     rule_references: [rule_references(:one)]),
      OpenStruct.new(id: rules(:two).ref_id,
                     rule_references: [rule_references(:two)]),
    ]

    assert_difference('RuleReferencesRule.count', 1) do
      save_rule_references_rules
    end

    assert_difference('RuleReferencesRule.count', 0) do
      save_rule_references_rules
    end
  end
end
