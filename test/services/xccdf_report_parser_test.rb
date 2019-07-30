# frozen_string_literal: true

require 'test_helper'

class XCCDFReportParserTest < ActiveSupport::TestCase
  setup do
    fake_report = file_fixture('xccdf_report.xml').read
    @profile = {
      'xccdf_org.ssgproject.content_profile_standard' =>
      'Standard System Security Profile for Fedora'
    }
    @host_id = SecureRandom.uuid
    @report_parser = ::XCCDFReportParser
                     .new(fake_report,
                          'account' => accounts(:test).account_number,
                          'b64_identity' => 'b64_fake_identity',
                          'id' => @host_id,
                          'metadata' => {
                            'fqdn' => 'lenovolobato.lobatolan.home'
                          })
    # A hack to skip API calls in the test env for the time being
    connection = mock('faraday_connection')
    HostInventoryAPI.any_instance.stubs(:connection).returns(connection)
    get_body = {
      'results' => [{ 'id' => @host_id, 'account' => accounts(:test) }]
    }
    connection.stubs(:get).returns(OpenStruct.new(body: get_body.to_json))
    post_body = {
      'data' => [{ 'host' => { 'name' => @report_parser.report_host } }]
    }
    connection.stubs(:post).returns(OpenStruct.new(body: post_body.to_json))
  end

  context 'profile' do
    should 'save a new profile if it did not exist before' do
      assert_difference('Profile.count', 1) do
        @report_parser.save_profiles
      end
    end

    should 'not save a new profile if it existed before' do
      Profile.create(
        ref_id: 'xccdf_org.ssgproject.content_profile_standard',
        name: @profile['xccdf_org.ssgproject.content_profile_standard'],
        account: accounts(:test)
      )
      assert_difference('Profile.count', 0) do
        @report_parser.save_profiles
      end
    end

    should 'not save more than one profile when there are no test results' do
      fake_report = file_fixture('rhel-xccdf-report.xml').read
      @profile = {
        'xccdf_org.ssgproject.content_profile_rht-ccp' =>
        'Red Hat Corporate Profile for Certified Cloud Providers (RH CCP)'
      }
      @report_parser = ::XCCDFReportParser
                       .new(fake_report,
                            'account' => accounts(:test).account_number,
                            'id' => @host_id,
                            'b64_identity' => 'b64_fake_identity',
                            'metadata' => {
                              'fqdn' => 'lenovolobato.lobatolan.home'
                            })
      assert_equal 1, @report_parser.oscap_parser.profiles.count
    end
  end

  context 'host' do
    should 'be able to parse host name' do
      assert_equal 'lenovolobato.lobatolan.home', @report_parser.report_host
    end

    should 'save the hostname in db' do
      assert_difference('Host.count', 1) do
        @report_parser.save_host
        assert Host.find_by(name: @report_parser.report_host)
      end
    end

    should 'return the host object even if it already existed' do
      HostInventoryAPI.any_instance
                      .stubs(:host_already_in_inventory)
                      .returns('id' => @host_id)
      Host.create(id: @host_id, name: @report_parser.report_host,
                  account: accounts(:test))

      assert_difference('Host.count', 0) do
        new_host = @report_parser.save_host
        assert_equal(
          new_host, Host.find_by(name: @report_parser.report_host)
        )
      end
    end

    should 'update the name of an existing host' do
      HostInventoryAPI.any_instance
                      .stubs(:host_already_in_inventory)
                      .returns('id' => @host_id)
      Host.create(id: @host_id, name: 'some.other.hostname',
                  account: accounts(:test))

      assert_difference('Host.count', 0) do
        new_host = @report_parser.save_host
        assert_equal(
          new_host, Host.find_by(name: @report_parser.report_host)
        )
      end
    end
  end

  context 'rule results' do
    should 'save them, associate them with a rule and a host' do
      assert_difference('RuleResult.count', 367) do
        rule_results = @report_parser.save_all
        assert_equal @report_parser.report_host,
                     RuleResult.find(rule_results.ids.sample).host.name
        rule_names = RuleResult.where(id: rule_results.ids).map(&:rule)
                               .pluck(:ref_id)
        assert rule_names.include?(@report_parser.oscap_parser.rule_ids.sample)
        @report_parser.oscap_parser.rule_results.each do |rule_result|
          assert_equal rule_result.result,
                       RuleResult.joins(:rule)
                                 .find_by(rules: { ref_id: rule_result.id })
                                 .result
        end
      end
    end
  end

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

    should 'link the rules with the profile' do
      @report_parser.save_profiles
      new_rules = @report_parser.save_rules
      assert_equal @profile.keys.first,
                   Rule.find(new_rules.ids.sample).profiles.first.ref_id
    end

    should 'save new rules in the database, ignore old rules' do
      (rule1 = Rule.new(ref_id: @arbitrary_rules[0])).save(validate: false)
      (rule2 = Rule.new(ref_id: @arbitrary_rules[1])).save(validate: false)
      assert_difference('Rule.count', 365) do
        new_rules = @report_parser.save_rules
        old_rules_found = Rule.where(id: new_rules.ids).find_all do |rule|
          [rule1.ref_id, rule2.ref_id].include?(rule.ref_id)
        end
        assert_empty old_rules_found
      end
    end

    should 'not try to append already assigned profiles to a rule' do
      (rule = Rule.new(ref_id: @arbitrary_rules[0])).save(validate: false)
      rule.profiles << profiles(:one)
      Profile.create(ref_id: @profile.keys[0], name: @profile.values[0])
      assert_nothing_raised do
        @report_parser.add_profiles_to_old_rules(
          Rule.where(ref_id: rule.ref_id), Profile.where(ref_id: @profile.keys)
        )
      end
      assert_equal 2, rule.profiles.count
      assert_includes rule.profiles, profiles(:one)
    end
  end
end
