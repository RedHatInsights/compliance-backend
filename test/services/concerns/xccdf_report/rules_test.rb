# frozen_string_literal: true

require 'test_helper'
require 'xccdf_report/rules'

class RulesTest < ActiveSupport::TestCase
  include XCCDFReport::Rules
  include XCCDFReport::Profiles

  def test_result
    OpenStruct.new(id: ['xccdf_org.ssgproject.content_profile_standard'])
  end

  setup do
    @oscap_parser = OpenscapParser::Base.new(
      file_fixture('xccdf_report.xml').read
    )
    @account = accounts(:test)
  end

  test 'save all rules as new' do
    assert_difference('Rule.count', 367) do
      save_rules
    end
  end

  test 'returns rules already saved in the report' do
    rule = Rule.new.from_oscap_object(@oscap_parser.rule_objects.first)
    rule.save
    assert_includes rules_already_saved, rule
  end

  test 'save all rules and add profiles to pre existing one' do
    profile = Profile.create(ref_id: @oscap_parser.profiles.keys.first,
                             name: @oscap_parser.profiles.keys.first,
                             account_id: accounts(:test).id)
    rule = Rule.new.from_oscap_object(@oscap_parser.rule_objects.first)
    rule.save
    assert_difference('Rule.count', 366) do
      save_rules
    end

    assert_includes rule.profiles, profile
  end

  test 'only new rule references are saved' do
    stubs(:new_rules).returns(
      [OpenStruct.new(references: [{ label: 'foo', href: '' }])]
    )

    assert_difference('RuleReference.count', 1) do
      save_rule_references
    end

    stubs(:new_rules).returns(
      [OpenStruct.new(references: [{ label: 'foo', href: '' },
                                   { label: 'bar', href: '' }])]
    )

    assert_difference('RuleReference.count', 1) do
      save_rule_references
    end
  end
end
