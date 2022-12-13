# frozen_string_literal: true

require 'test_helper'

class XccdfReportParserTest < ActiveSupport::TestCase
  class TestParser < ::XccdfReportParser
    attr_accessor :op_benchmark, :op_test_result, :op_profiles, :op_rules,
                  :op_rule_results, :op_rule_groups, :rule_groups
    attr_reader :test_result_file, :host, :profiles

    def package_name
      nil
    end
  end

  setup do
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    fake_report = file_fixture('xccdf_report.xml').read
    @profile = {
      'xccdf_org.ssgproject.content_profile_standard' =>
      'Standard System Security Profile for Fedora'
    }
    @account = FactoryBot.create(:account)
    @host = FactoryBot.create(
      :host,
      org_id: @account.org_id,
      display_name: 'MyStringone'
    )

    @report_parser = TestParser
                     .new(fake_report,
                          'org_id' => @account.org_id,
                          'b64_identity' => @account.b64_identity,
                          'id' => @host.id,
                          'metadata' => {
                            'display_name' => @host.name
                          })
    @report_parser.host.stubs(:os_major_version).returns(8)
    @report_parser.host.stubs(:os_minor_version).returns(3)
    @report_parser.set_openscap_parser_data
    stub_supported_ssg([@host], ['0.1.40'])
  end

  context 'benchmark' do
    setup do
      @report_parser.stubs(:external_report?)
    end

    should 'never save a new benchmark that is not in the support matrix' do
      @report_parser.op_benchmark.stubs(:version).returns('0.1.15')
      assert_difference('Xccdf::Benchmark.count', 0) do
        assert_raises(XccdfReportParser::UnknownBenchmarkError) do
          @report_parser.save_all
        end
      end
    end

    should 'not save missing benchmarks for RHEL8' do
      @report_parser.expects(:save_all_benchmark_info).never
      @report_parser.save_missing_supported_benchmark
    end

    should 'save an unknown RHEL6 benchmark that is in the support matrix' do
      @report_parser.op_benchmark.stubs(:id).returns('xccdf_org.ssgproject.content_benchmark_RHEL-6')
      @report_parser.host.stubs(:os_major_version).returns(6)

      assert_difference('Xccdf::Benchmark.count', 1) do
        assert_nothing_raised do
          @report_parser.save_all
        end
      end
    end

    should 'find and return an existing benchmark' do
      @report_parser.save_all_benchmark_info
      assert_no_difference('Xccdf::Benchmark.count') do
        assert_nothing_raised do
          @report_parser.save_all
        end
      end
    end
  end

  context 'profile' do
    setup do
      @report_parser.save_benchmark
      @report_parser.stubs(:external_report?)
    end

    should 'never save a new canonical profile if it did not exist before' do
      @report_parser.stubs(:save_missing_supported_benchmark)
      assert_difference('Profile.count', 0) do
        assert_raises(XccdfReportParser::UnknownProfileError) do
          @report_parser.save_all
        end
      end
    end
  end

  context 'rule_group' do
    setup do
      @report_parser.save_benchmark
      @report_parser.save_profiles
    end
  end

  context 'host' do
    setup do
      @report_parser.save_all_benchmark_info
    end

    should 'be able to parse host name' do
      assert_equal(
        @host.name,
        @report_parser.test_result_file.test_result.host
      )
    end

    should 'raise on OS version mismatch' do
      @report_parser.host.stubs(:os_major_version).returns(7)
      assert_raises(XccdfReportParser::OSVersionMismatch) do
        @report_parser.check_os_version
      end
    end
  end

  context 'rule results' do
    setup do
      @report_parser.stubs(:external_report?)
      @report_parser.save_all_benchmark_info
    end

    should 'save them, associate them with a rule and a host' do
      profile = FactoryBot.create(
        :profile, :with_rules, rule_count: 1, account: @account, policy: nil
      )
      tr = FactoryBot.create(:test_result, host: @host, profile: profile)
      FactoryBot.create(
        :rule_result,
        rule: profile.rules.first,
        test_result: tr,
        host: @host
      )

      assert_difference('RuleResult.count', 58) do
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

    should 'provide failed results' do
      @report_parser.save_all
      failed_rule_results = @report_parser.failed_rule_results
      assert_equal failed_rule_results.count, 45
      assert failed_rule_results.all? do |rr|
        ::RuleResult::FAIL.include?(rr.result)
      end
    end

    should 'provide failed rules' do
      @report_parser.save_all
      assert_equal @report_parser.failed_rules.count,
                   @report_parser.failed_rule_results.count
    end
  end

  context 'error handling' do
    should 'raise error if message ID is not present' do
      assert_raises(XccdfReportParser::MissingIdError) do
        TestParser.new(
          'fakereport',
          'org_id' => @account.org_id,
          'b64_identity' => @account.b64_identity,
          'metadata' => { 'display_name': '123' }
        )
      end
    end

    should 'validate b64_identity is present' do
      assert_raises(XccdfReportParser::MissingIdError) do
        TestParser.new(
          'fakereport',
          'org_id' => @account.org_id,
          'id' => @host.id,
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
      @report_parser.save_value_definitions
      @report_parser.save_profiles
      @report_parser.save_rule_groups
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

    should 'never save new rules in the database' do
      @report_parser.stubs(:save_missing_supported_benchmark)
      @report_parser.stubs(:external_report?)
      Rule.new(
        ref_id: @arbitrary_rules[0],
        benchmark: @report_parser.benchmark
      ).save(validate: false)
      Rule.new(
        ref_id: @arbitrary_rules[1],
        benchmark: @report_parser.benchmark
      ).save(validate: false)

      assert_difference('Rule.count', 0) do
        assert_raises(XccdfReportParser::UnknownRuleError) do
          @report_parser.save_all
        end
      end
    end

    should 'not try to append already assigned profiles to a rule' do
      profile = Profile.create!(
        ref_id: @profile.keys[0],
        name: @profile.values[0],
        benchmark: FactoryBot.create(:benchmark)
      )
      rule = Rule.create!(
        ref_id: @arbitrary_rules[0],
        title: 'foo',
        description: 'foo',
        severity: 'low',
        benchmark: profile.benchmark,
        profiles: [profile],
        rule_group: FactoryBot.create(:rule_group, benchmark: profile.benchmark)
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
      assert_empty(Profile.where(parent_profile: parent_profile))
      assert_difference(
        -> { Profile.count } => 1,
        lambda {
          Profile.find_by(parent_profile: parent_profile)&.rules&.count || 0
        } => parent_profile.rules.count
      ) do
        @report_parser.save_host_profile
      end
    end

    should 'not add rules to existing profiles' do
      parent_profile = Profile.canonical.find_by(
        ref_id: @report_parser.op_test_result.profile_id,
        benchmark: @report_parser.benchmark
      )
      (profile = Profile.new(
        parent_profile: parent_profile,
        account: @account
      ).fill_from_parent).update!(rules: [])

      assert profile.persisted?

      assert_difference(
        -> { Profile.count } => 0,
        -> { profile.reload.rules.count } => 0
      ) do
        @report_parser.save_rules
        @report_parser.save_profile_rules
        @report_parser.save_host_profile
      end
    end
  end

  context 'datastream-based reports only' do
    should 'raise an error if the report is not coming from a datastream' do
      fake_report = file_fixture('rhel-xccdf-report-wrong.xml').read
      assert_raises(XccdfReportParser::WrongFormatError) do
        TestParser.new(
          fake_report,
          'org_id' => @account.org_id,
          'id' => @host.id,
          'b64_identity' => @account.b64_identity,
          'metadata' => {
            'display_name' => @host.name
          }
        )
      end
    end
  end

  context 'finding an associated policy' do
    should 'raise an error with no policy found (external report)' do
      @report_parser.stubs(:external_report?).returns(true)
      assert_raises(XccdfReportParser::ExternalReportError) do
        @report_parser.check_for_external_reports
      end
    end

    should 'find a policy profile by hosts, account, and ref_id' do
      profile = FactoryBot.create(
        :canonical_profile,
        ref_id: 'xccdf_org.ssgproject.content_profile_standard'
      )

      policy = FactoryBot.create(
        :policy,
        account: @account,
        hosts: [@report_parser.host]
      )
      FactoryBot.create(
        :policy,
        account: @account,
        hosts: [@report_parser.host]
      )

      @report_parser.stubs(:external_report?)
      Profile.any_instance.expects(:clone_to).with(policy: nil,
                                                   account: @account,
                                                   os_minor_version: '3')
      @report_parser.save_host_profile

      profile.update!(policy: policy, account: @account)
      Profile.any_instance.expects(:clone_to).with(policy: policy,
                                                   account: @account,
                                                   os_minor_version: '3')
      @report_parser.save_host_profile
    end
  end
end
