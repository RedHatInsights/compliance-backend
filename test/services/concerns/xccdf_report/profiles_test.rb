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
    @account = OpenStruct.new(id: 1)
    @host = OpenStruct.new(id: 2)
    @oscap_parser = OpenscapParser::Base.new(
      file_fixture('xccdf_report.xml').read
    )
  end

  test 'save_profiles' do
    before = Profile.count
    save_profiles
    now = Profile.count
    assert_equal before + 1, now
    save_profiles
    assert_equal now, Profile.count
  end

  test 'host_new_profiles' do
    save_profiles.first.stubs(:host).returns(@host)
    assert_equal 1, host_new_profiles.length
  end
end
