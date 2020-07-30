# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rule_references'

# A class to test saving RuleReferences from OpenscapParser
class RuleReferencesTest < ActiveSupport::TestCase
  include Xccdf::RuleReferences

  test 'only new rule references are saved' do
    @op_rule_references = [OpenStruct.new(label: 'foo', href: '')]
    stubs(:new_rules).returns(
      [OpenStruct.new(references: @op_rule_references)]
    )

    assert_difference('RuleReference.count', 1) do
      save_rule_references
    end

    @existing_rule_references, @new_rule_references = nil # un-cache it from ||=
    @op_rule_references = [OpenStruct.new(label: 'foo', href: ''),
                           OpenStruct.new(label: 'bar', href: '')]
    stubs(:new_rules).returns(
      [OpenStruct.new(references: @op_rule_references)]
    )

    assert_difference('RuleReference.count', 1) do
      save_rule_references
    end
  end
end
