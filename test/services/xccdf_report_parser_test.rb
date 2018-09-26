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
      ref_id: 'xccdf_org.ssgproject.content_profile_standard',
      name: @profile['xccdf_org.ssgproject.content_profile_standard']
    )
    assert_difference('Profile.count', 0) do
      @report_parser.save_profiles
    end
  end

  test 'score can be parsed' do
    assert_equal(16.220237731933594, @report_parser.score)
  end

  # rubocop:disable Metrics/BlockLength
  context 'rules' do
    setup do
      @arbitrary_rules = [
        # rubocop:disable Metrics/LineLength
        'xccdf_org.ssgproject.content_rule_dir_perms_world_writable_system_owned',
        'xccdf_org.ssgproject.content_rule_bios_enable_execution_restrictions',
        'xccdf_org.ssgproject.content_rule_gconf_gnome_screensaver_lock_enabled',
        'xccdf_org.ssgproject.content_rule_selinux_all_devicefiles_labeled'
        # rubocop:enable Metrics/LineLength
      ]
    end

    should 'list all rules' do
      assert_empty(@arbitrary_rules - @report_parser.rule_ids)
    end

    should 'link the rules with the profile' do
      @report_parser.save_profiles
      new_rules = @report_parser.save_rules
      assert_equal @profile.keys.first, new_rules.sample.profiles.first.ref_id
    end

    should 'save new rules in the database, ignore old rules' do
      rule1 = Rule.create(ref_id: @arbitrary_rules[0])
      rule2 = Rule.create(ref_id: @arbitrary_rules[1])
      assert_difference('Rule.count', 365) do
        new_rules = @report_parser.save_rules
        old_rules_found = new_rules.find_all do |rule|
          [rule1.ref_id, rule2.ref_id].include?(rule.ref_id)
        end
        assert_empty old_rules_found
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
