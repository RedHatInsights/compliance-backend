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

  context 'rules' do
    setup do
      @arbitrary_rules = [
        'xccdf_org.ssgproject.content_rule_dir_perms_world_writable_system_owned',
        'xccdf_org.ssgproject.content_rule_bios_enable_execution_restrictions',
        'xccdf_org.ssgproject.content_rule_gconf_gnome_screensaver_lock_enabled',
        'xccdf_org.ssgproject.content_rule_selinux_all_devicefiles_labeled'
      ]
    end

    should 'rules can be listed' do
      assert_empty(@arbitrary_rules - @report_parser.rule_ids)
    end

    should 'new rules are saved in the database, old rules are ignored' do
      Rule.create(:ref_id => @arbitrary_rules[0])
      Rule.create(:ref_id => @arbitrary_rules[1])
      assert_difference('Rule.count', 2) do
        @report_parser.save_rules
      end
    end
  end
end
