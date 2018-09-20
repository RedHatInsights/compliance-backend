# frozen_string_literal: true

require 'test_helper'

class XCCDFReportParserTest < ActiveSupport::TestCase
  test 'policy can be parsed' do
    fake_report = file_fixture('xccdf_report.xml').to_path
    assert_equal(
      [['xccdf_org.ssgproject.content_profile_standard',
        'Standard System Security Profile for Fedora']],
      ::XCCDFReportParser.new(fake_report).profiles
    )
  end
end
