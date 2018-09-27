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

  context 'profile' do
    should 'be able to parse it' do
      assert_equal(@profile, @report_parser.profiles)
    end

    should 'save a new profile if it did not exist before' do
      assert_difference('Profile.count', 1) do
        @report_parser.save_profiles
      end
    end

    should 'not save a new profile if it existed before' do
      Profile.create(
        ref_id: 'xccdf_org.ssgproject.content_profile_standard',
        name: @profile['xccdf_org.ssgproject.content_profile_standard']
      )
      assert_difference('Profile.count', 0) do
        @report_parser.save_profiles
      end
    end
  end

  context 'host' do
    should 'be able to parse host name' do
      assert_equal 'lenovolobato.lobatolan.home', @report_parser.host
    end

    should 'save the hostname in db' do
      assert_difference('Host.count', 1) do
        @report_parser.save_host
        assert Host.find_by(name: @report_parser.host)
      end
    end

    should 'return the host object even if it already existed' do
      Host.create(name: @report_parser.host)
      assert_difference('Host.count', 0) do
        new_host = @report_parser.save_host
        assert_equal(
          new_host, Host.find_by(name: @report_parser.host)
        )
      end
    end
  end

  context 'rule results' do
    should 'save them, associate them with a rule and a host' do
      assert_difference('RuleResult.count', 367) do
        rule_results = @report_parser.save_rule_results
        assert_equal @report_parser.host, rule_results.sample.host.name
        rule_names = rule_results.map { |rule_result| rule_result.rule.ref_id }
        assert rule_names.include?(@report_parser.rule_ids.sample)
      end
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
