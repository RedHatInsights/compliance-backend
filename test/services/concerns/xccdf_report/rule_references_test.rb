# frozen_string_literal: true

require 'test_helper'
require 'xccdf_report/rule_references'

class RulesTest < ActiveSupport::TestCase
  include XCCDFReport::RuleReferences

  test 'only new rule references are saved' do
    stubs(:new_rules).returns(
      [OpenStruct.new(references: [{ label: 'foo', href: '' }])]
    )

    assert_difference('RuleReference.count', 1) do
      save_rule_references
    end

    @rule_references = nil # un-cache it from ||=
    stubs(:new_rules).returns(
      [OpenStruct.new(references: [{ label: 'foo', href: '' },
                                   { label: 'bar', href: '' }])]
    )

    assert_difference('RuleReference.count', 1) do
      save_rule_references
    end
  end
end
