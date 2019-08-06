# frozen_string_literal: true

require 'test_helper'
require 'xccdf_report/profiles'

class ProfilesTest < ActiveSupport::TestCase
  def test_result
    OpenStruct.new(id: ['xccdf_org.ssgproject.content_profile_standard'])
  end

  def report_description
    'description'
  end

  include XCCDFReport::Profiles

  setup do
    @account = accounts(:test)
    @host = hosts(:one)
    @oscap_parser = OpenscapParser::Base.new(
      file_fixture('xccdf_report.xml').read
    )
  end

  test 'save_profiles' do
    assert_difference('Profile.count', 1) do
      save_profiles
    end

    assert_no_difference('Profile.count') do
      save_profiles
    end
  end

  test 'host_new_profiles' do
    save_profiles.first.stubs(:host).returns(@host)
    assert_equal 1, host_new_profiles.length
  end
end
