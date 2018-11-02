# frozen_string_literal: true

require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  should validate_uniqueness_of :ref_id
  should validate_presence_of :ref_id

  setup do
    fake_report = file_fixture('xccdf_report.xml').to_path
    @report_parser = ::XCCDFReportParser.new(fake_report, users(:test))
    @rule_objects = @report_parser.rule_objects
    @selinux_rule_id = 'xccdf_org.ssgproject.content_rule'\
      '_selinux_all_devicefiles_labeled'
  end

  test 'creates rules from ruby-openscap Rule object' do
    Rule.new.from_oscap_object(@rule_objects[@selinux_rule_id])
  end
end
