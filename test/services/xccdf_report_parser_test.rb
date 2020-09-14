# frozen_string_literal: true

require 'test_helper'

class XccdfReportParserTest < ActiveSupport::TestCase
  class TestParser < ::XccdfReportParser
    attr_accessor :op_benchmark, :op_test_result, :op_profiles, :op_rules,
                  :op_rule_results, :rules
    attr_reader :test_result_file, :host, :profiles
  end

  setup do
    fake_report = file_fixture('xccdf_report.xml').read
    @profile = {
      'xccdf_org.ssgproject.content_profile_standard' =>
      'Standard System Security Profile for Fedora'
    }
    @host_id = SecureRandom.uuid
    @report_parser = TestParser
                     .new(fake_report,
                          'account' => accounts(:test).account_number,
                          'b64_identity' => 'b64_fake_identity',
                          'id' => @host_id,
                          'metadata' => {
                            'display_name' => 'lenovolobato.lobatolan.home'
                          })
    @report_parser.set_openscap_parser_data
    # A hack to skip API calls in the test env for the time being
    connection = mock('faraday_connection')
    Platform.stubs(:connection).returns(connection)
    get_body = {
      'results' => [
        { 'id' => @host_id,
          'account' => accounts(:test).account_number,
          'display_name' => @report_parser.test_result_file.test_result.host }
      ]
    }
    connection.stubs(:get).with(
      "#{::Settings.host_inventory_url}#{Settings.path_prefix}" \
      "/inventory/v1/hosts/#{@host_id}",
      {}, X_RH_IDENTITY: 'b64_fake_identity'
    ).returns(OpenStruct.new(body: get_body.to_json))
    post_body = {
      'data' => [{ 'host' => {
        'name' => @report_parser.test_result_file.test_result.host
      } }]
    }
    connection.stubs(:post).returns(OpenStruct.new(body: post_body.to_json))
    system_profile_body = {
      'results' => [
        {
          'id' => @host_id,
          'system_profile' => {
            'os_release': '8.3'
          }
        }
      ]
    }
    connection.stubs(:get).with(
      "#{::Settings.host_inventory_url}#{Settings.path_prefix}" \
      "/inventory/v1/hosts/#{[@host_id].join(',')}/system_profile",
      { per_page: 50, page: 1 },
      X_RH_IDENTITY: 'b64_fake_identity'
    ).returns(OpenStruct.new(body: system_profile_body.to_json))
  end

  context 'benchmark' do
    should 'save a new benchmark' do
      assert_difference('Xccdf::Benchmark.count', 1) do
        @report_parser.save_benchmark
      end
    end

    should 'find and return an existing benchmark' do
      @report_parser.save_benchmark
      assert_no_difference('Xccdf::Benchmark.count') do
        @report_parser.save_benchmark
      end
    end
  end

  context 'profile' do
    setup do
      @report_parser.save_benchmark
    end

    should 'save a new profile if it did not exist before' do
      assert_difference('Profile.count', 1) do
        @report_parser.save_profiles
      end
    end

    should 'not save a new profile if it existed before' do
      Profile.create(
        ref_id: 'xccdf_org.ssgproject.content_profile_standard',
        name: @profile['xccdf_org.ssgproject.content_profile_standard'],
        benchmark: @report_parser.benchmark
      )
      assert_difference('Profile.count', 0) do
        @report_parser.save_profiles
      end
    end

    should 'save all benchmark profiles even when there are no test results' do
      fake_report = file_fixture('rhel-xccdf-report.xml').read
      @profile = {
        'xccdf_org.ssgproject.content_profile_rht-ccp' =>
        'Red Hat Corporate Profile for Certified Cloud Providers (RH CCP)'
      }
      @report_parser = TestParser
                       .new(fake_report,
                            'account' => accounts(:test).account_number,
                            'id' => @host_id,
                            'b64_identity' => 'b64_fake_identity',
                            'metadata' => {
                              'display_name' => 'lenovolobato.lobatolan.home'
                            })
      assert_equal 10, @report_parser.op_benchmark.profiles.count
    end
  end

  context 'host' do
    setup do
      @report_parser.save_all_benchmark_info
    end

    should 'be able to parse host name' do
      assert_equal(
        'lenovolobato.lobatolan.home',
        @report_parser.test_result_file.test_result.host
      )
    end

    should 'save the hostname in db' do
      assert_difference('Host.count', 1) do
        @report_parser.save_host
        assert Host.find_by(
          name: @report_parser.test_result_file.test_result.host
        )
      end
    end

    should 'return the host object even if it already existed' do
      Host.create(id: @host_id,
                  name: @report_parser.test_result_file.test_result.host,
                  account: accounts(:test))

      assert_difference('Host.count', 0) do
        @report_parser.save_host
        assert_equal(
          @report_parser.host,
          Host.find_by(name: @report_parser.test_result_file.test_result.host)
        )
      end
    end

    should 'update the name of an existing host' do
      Host.create(id: @host_id, name: 'some.other.hostname',
                  account: accounts(:test))

      assert_difference('Host.count', 0) do
        @profiles = []
        @report_parser.save_host
        assert_equal(
          @report_parser.host,
          Host.find_by(name: @report_parser.test_result_file.test_result.host)
        )
      end
    end
  end

  context 'rule results' do
    should 'save them, associate them with a rule and a host' do
      assert_difference('RuleResult.count', 59) do
        @report_parser.save_all
        rule_results = @report_parser.rule_results
        op_rule_results = @report_parser.op_rule_results
        selected_op_rule_results = op_rule_results.reject do |rr|
          RuleResult::NOT_SELECTED.include? rr.result
        end

        assert_equal @report_parser.test_result_file.test_result.host,
                     RuleResult.find(rule_results.sample.id).host.name
        rule_ids = Rule.includes(:rule_results)
                       .where(rule_results: { id: rule_results.map(&:id) })
                       .pluck(:ref_id)
        assert rule_ids.include?(selected_op_rule_results.sample.id)
        selected_op_rule_results.each do |rule_result|
          assert_equal rule_result.result,
                       RuleResult.joins(:rule)
                                 .find_by(rules: { ref_id: rule_result.id })
                                 .result
        end
      end
    end
  end

  context 'missing ID' do
    should 'raise error if message ID is not present' do
      assert_raises(::MissingIdError) do
        TestParser.new(
          'fakereport',
          'account' => accounts(:test).account_number,
          'b64_identity' => 'b64_fake_identity',
          'metadata' => { 'display_name': '123' }
        )
      end
    end
  end

  context 'rules' do
    setup do
      @arbitrary_rules = [
        # rubocop:disable Layout/LineLength
        'xccdf_org.ssgproject.content_rule_dir_perms_world_writable_system_owned',
        'xccdf_org.ssgproject.content_rule_bios_enable_execution_restrictions',
        'xccdf_org.ssgproject.content_rule_gconf_gnome_screensaver_lock_enabled',
        'xccdf_org.ssgproject.content_rule_selinux_all_devicefiles_labeled'
        # rubocop:enable Layout/LineLength
      ]
      @report_parser.save_benchmark
      @report_parser.save_profiles
    end

    should 'link the rules with the profile' do
      @report_parser.save_rules
      @report_parser.save_profile_rules
      rule_ref_id = @report_parser.op_profiles
                                  .find { |p| p.id == @profile.keys.first }
                                  .selected_rule_ids.sample
      rule = Rule.find_by(ref_id: rule_ref_id)
      assert_equal @profile.keys.first, rule.profiles.pluck(:ref_id).first
    end

    should 'save new rules in the database, ignore old rules' do
      Rule.new(
        ref_id: @arbitrary_rules[0],
        benchmark: @report_parser.benchmark
      ).save(validate: false)
      Rule.new(
        ref_id: @arbitrary_rules[1],
        benchmark: @report_parser.benchmark
      ).save(validate: false)

      assert_difference('Rule.count', 365) do
        @report_parser.save_rules
      end

      @report_parser.rules = nil

      assert_difference('Rule.count', 0) do
        @report_parser.save_rules
      end

      assert_equal @report_parser.op_rules.count, @report_parser.rules.count
    end

    should 'not try to append already assigned profiles to a rule' do
      profile = Profile.create!(
        ref_id: @profile.keys[0],
        name: @profile.values[0],
        benchmark: benchmarks(:one)
      )
      rule = Rule.create!(
        ref_id: @arbitrary_rules[0],
        title: 'foo',
        description: 'foo',
        severity: 'low',
        benchmark: benchmarks(:one),
        profiles: [profile]
      )
      assert_nothing_raised do
        assert_difference('rule.profiles.count', 0) do
          @report_parser.save_rules
          @report_parser.save_profile_rules
        end
      end
      assert_includes rule.profiles, profile
    end

    should 'add rules to new non-canonical (external) profiles' do
      parent_profile = Profile.canonical.find_by(
        ref_id: @report_parser.op_test_result.profile_id,
        benchmark: @report_parser.benchmark
      )

      @report_parser.save_rules
      @report_parser.save_profile_rules
      @report_parser.save_host
      assert_empty(Profile.where(parent_profile: parent_profile))
      assert_difference(
        -> { Profile.count } => 1,
        lambda {
          Profile.find_by(parent_profile: parent_profile)&.rules&.count || 0
        } => parent_profile.rules.count
      ) do
        @report_parser.save_profile_host
      end
    end

    should 'not add rules to existing profiles' do
      parent_profile = Profile.canonical.find_by(
        ref_id: @report_parser.op_test_result.profile_id,
        benchmark: @report_parser.benchmark
      )
      (profile = Profile.new(
        parent_profile: parent_profile,
        account: accounts(:test)
      ).fill_from_parent).update!(rules: [])

      assert profile.persisted?

      assert_difference(
        -> { Profile.count } => 0,
        -> { profile.reload.rules.count } => 0
      ) do
        @report_parser.save_rules
        @report_parser.save_profile_rules
        @report_parser.save_host
        @report_parser.save_profile_host
      end
    end
  end

  context 'datastream-based reports only' do
    should 'raise an error if the report is not coming from a datastream' do
      fake_report = file_fixture('rhel-xccdf-report-wrong.xml').read
      assert_raises(::WrongFormatError) do
        TestParser.new(
          fake_report,
          'account' => accounts(:test).account_number,
          'id' => @host_id,
          'b64_identity' => 'b64_fake_identity',
          'metadata' => {
            'display_name' => 'lenovolobato.lobatolan.home'
          }
        )
      end
    end
  end
end
