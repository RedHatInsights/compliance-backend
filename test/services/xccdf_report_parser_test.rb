# frozen_string_literal: true

require 'test_helper'

class XCCDFReportParserTest < ActiveSupport::TestCase
  test 'profile can be parsed' do
    fake_report = file_fixture('xccdf_report.xml').to_path
    assert_equal(
      [['xccdf_org.ssgproject.content_profile_standard',
        'Standard System Security Profile for Fedora']],
      ::XCCDFReportParser.new(fake_report).profiles
    )
  end

  test 'score can be parsed' do
    fake_report = file_fixture('xccdf_report.xml').to_path
    assert_equal(
      16.220237731933594,
      ::XCCDFReportParser.new(fake_report).score
    )
  end
end
