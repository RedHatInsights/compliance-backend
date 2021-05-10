# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rule_identifiers'

# A class to test saving RuleReferences from OpenscapParser
class RuleReferencesTest < ActiveSupport::TestCase
  class MockParser
    attr_accessor :new_rules

    include Xccdf::RuleIdentifiers
  end

  test 'identifiers of new rules are saved' do
    parser = MockParser.new
    rule = FactoryBot.create(:rule)
    rule.op_source = OpenStruct.new(
      identifier: OpenStruct.new(
        label: 'foo label',
        system: 'http://123.foo'
      )
    )

    parser.new_rules = [rule]

    assert_difference('RuleIdentifier.count', 1) do
      parser.save_rule_identifiers
    end

    assert_no_difference('RuleReference.count') do
      parser.save_rule_identifiers
    end
  end
end
