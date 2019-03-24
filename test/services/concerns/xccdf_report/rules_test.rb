# frozen_string_literal: true

require 'test_helper'
require 'xccdf_report/rules'
require 'openscap/source'
require 'openscap/xccdf/benchmark'

class RulesTest < ActiveSupport::TestCase
  include XCCDFReport::Rules
  include XCCDFReport::Profiles

  def test_result
    OpenStruct.new(id: ['xccdf_org.ssgproject.content_profile_standard'])
  end

  setup do
    @report_path = 'test/fixtures/files/xccdf_report.xml'
    @source = ::OpenSCAP::Source.new(@report_path)
    @benchmark = ::OpenSCAP::Xccdf::Benchmark.new(@source)
  end

  test 'save all rules as new' do
    assert_difference('Rule.count', 367) do
      save_rules
    end
  end

  test 'returns rules already saved in the report' do
    rule = Rule.new.from_oscap_object(rule_objects.first)
    rule.save
    assert_includes rules_already_saved, rule
  end

  test 'save all rules and add profiles to pre existing one' do
    profile = Profile.create(ref_id: profiles.keys.first,
                             name: profiles.keys.first)
    rule = Rule.new.from_oscap_object(rule_objects.first)
    rule.save
    assert_difference('Rule.count', 366) do
      save_rules
    end

    assert_includes rule.profiles, profile
  end
end
