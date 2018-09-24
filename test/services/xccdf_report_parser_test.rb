# frozen_string_literal: true

require 'test_helper'

class XCCDFReportParserTest < ActiveSupport::TestCase
  setup do
    fake_report = file_fixture('xccdf_report.xml').to_path
    @profile = {
        'xccdf_org.ssgproject.content_profile_standard' =>
        'Standard System Security Profile for Fedora'
      }
    @report_parser = ::XCCDFReportParser.new(fake_report)
  end

  test 'profile can be parsed' do
    assert_equal(@profile, @report_parser.profiles)
  end

  test 'save_profile saves a new profile if it did not exist before' do
    assert_difference('Profile.count', 1) do
      @report_parser.save_profiles
    end
  end

  test 'save_profile does not save a new profile if it existed before' do
    Profile.create(
      :ref_id => 'xccdf_org.ssgproject.content_profile_standard',
      :name => @profile['xccdf_org.ssgproject.content_profile_standard']
    )
    assert_difference('Profile.count', 0) do
      @report_parser.save_profiles
    end
  end

  test 'score can be parsed' do
    assert_equal(16.220237731933594, @report_parser.score)
  end
end
