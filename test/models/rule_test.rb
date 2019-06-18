# frozen_string_literal: true

require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  should validate_uniqueness_of :ref_id
  should validate_presence_of :ref_id

  setup do
    fake_report = file_fixture('xccdf_report.xml').read
    @rule_objects = OpenscapParser::Base.new(fake_report).rule_objects
  end

  test 'creates rules from ruby-openscap Rule object' do
    Rule.new.from_oscap_object(@rule_objects.first)
  end

  test 'host one is not compliant?' do
    assert_not rules(:one).compliant?(hosts(:one))
  end

  test 'host one is compliant?' do
    rule_result = rule_results(:one)
    RuleResult.expects(:find_by_sql).returns([rule_result])
    assert rules(:one).compliant?(hosts(:one))
  end
end
