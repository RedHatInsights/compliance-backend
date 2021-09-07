# frozen_string_literal: true

require 'test_helper'

class HostTest < ActiveSupport::TestCase
  should have_many(:rule_results)
  should have_many(:rules).through(:rule_results).source(:rule)
  should have_many(:policy_hosts)
  should have_many(:test_results)
  should have_many(:policies).through(:policy_hosts)
  should have_many(:assigned_profiles).through(:policies).source(:profiles)
  should have_many(:test_result_profiles).through(:test_results)

  setup do
    @account = FactoryBot.create(:account)
    @host1 = Host.find(FactoryBot.create(
      :host,
      account: @account.account_number,
      os_major_version: 7,
      os_minor_version: 4
    ).id)

    @host2 = Host.find(FactoryBot.create(
      :host,
      account: @account.account_number,
      os_major_version: 8,
      os_minor_version: 3
    ).id)
  end

  test 'host is readonly' do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      Host.new.save
    end
  end

  test 'with_policy scope / has_policy filter' do
    assert_equal 0, PolicyHost.count

    FactoryBot.create(:policy, account: @account, hosts: [@host1])

    assert_includes Host.with_policy, @host1
    assert_includes Host.search_for('has_policy=true'), @host1

    assert_not_includes Host.with_policy(false), @host1
    assert_not_includes Host.search_for('has_policy=false'), @host1

    assert_includes Host.with_policy(false), @host2
    assert_includes Host.search_for('has_policy=false'), @host2

    assert_not_includes Host.with_policy, @host2
    assert_not_includes Host.search_for('has_policy=true'), @host2
  end

  test 'OS major version scope and filter' do
    assert_includes Host.os_major_version(7), @host1
    assert_includes Host.search_for('os_major_version = 7'), @host1

    assert_not_includes Host.os_major_version(7, false), @host1
    assert_not_includes Host.search_for('os_major_version != 7'), @host1

    assert_includes Host.os_major_version(7, false), @host2
    assert_includes Host.search_for('os_major_version != 7'), @host2

    assert_not_includes Host.os_major_version(7), @host2
    assert_not_includes Host.search_for('os_major_version = 7'), @host2
  end

  test 'OS minor version scope and filter' do
    assert_includes Host.os_minor_version(4), @host1
    assert_includes Host.search_for('os_minor_version = 4'), @host1

    assert_not_includes Host.os_minor_version(4, false), @host1
    assert_not_includes Host.search_for('os_minor_version != 4'), @host1

    assert_includes Host.os_minor_version(4, false), @host2
    assert_includes Host.search_for('os_minor_version != 4'), @host2

    assert_not_includes Host.os_minor_version(4), @host2
    assert_not_includes Host.search_for('os_minor_version = 4'), @host2
  end

  test 'loose filter search' do
    assert_includes Host.search_for("\"#{@host1.display_name}\""), @host1
  end

  test 'host provides all profiles, assigned and from test results' do
    profile1 = FactoryBot.create(:profile, account: @account)
    profile2 = FactoryBot.create(:profile, :with_rules, account: @account)

    FactoryBot.create(:test_result, profile: profile2, host: @host1)
    profile1.policy.hosts << @host1

    assert_equal @host1.all_profiles.count, 2
    assert_includes @host1.all_profiles.map(&:id), profile1.id
    assert_includes @host1.all_profiles.map(&:id), profile2.id
  end

  test 'compliant returns a hash with all compliance statuses' do
    expected_result = 2.times.each_with_object({}) do |_, obj|
      profile = FactoryBot.create(
        :profile,
        :with_rules,
        account: @account
      )

      FactoryBot.create(
        :test_result,
        profile: profile,
        host: @host1
      )

      obj[profile.ref_id.to_s] = false
    end

    assert_equal expected_result, @host1.compliant
  end

  context 'test result dependent search methods' do
    setup do
      @profile = FactoryBot.create(
        :profile,
        :with_rules,
        account: @account,
        rule_count: 2
      )

      tr = FactoryBot.create(:test_result, profile: @profile, host: @host1)

      %w[pass fail].each_with_index do |status, idx|
        FactoryBot.create(
          :rule_result,
          host: @host1,
          test_result: tr,
          rule: @profile.rules[idx],
          result: status
        )
      end
    end

    should 'total_rules returns the number of rules' do
      assert_equal 2, @host1.last_scan_results.count
    end

    should 'rules_passed returns the number of rules that passed' do
      assert_equal 1, @host1.rules_passed
    end

    should 'rules_failed returns the number of rules that failed' do
      assert_equal 1, @host1.rules_failed
    end

    should 'compliance_score returns the percentage of rules that passed' do
      assert_equal 50.0, @host1.compliance_score
    end

    should 'fail to find based on compliance score without a policy' do
      RequestStore.clear!
      assert_raises(::ScopedSearch::QueryNotSupported) do
        Host.search_for('compliance_score >= 40 and compliance_score <= 60')
      end
    end

    should 'be able to find based on compliance score' do
      RequestStore.clear!

      assert_includes(
        Host.search_for("
          with_results_for_policy_id = #{@profile.policy_id} and (
            compliance_score >= #{@host1.test_results.first.score - 10} and
            compliance_score <= #{@host1.test_results.first.score + 10}
          )
        "),
        @host1
      )

      RequestStore.clear!

      assert_not_includes(
        Host.search_for("
          with_results_for_policy_id = #{@profile.policy_id} and (
            compliance_score >= 0 and
            compliance_score <= #{@host1.test_results.first.score - 1}
          )
        "),
        @host1
      )

      RequestStore.clear!
    end

    should 'be able to find based on compliance true/false' do
      User.current = FactoryBot.create(:user, account: @account)
      RequestStore.clear!
      assert_not_includes Host.search_for('compliant = true'), @host1
      assert_includes Host.search_for('compliant = false'), @host1
      assert_includes Host.search_for('compliant != true'), @host1
      assert_not_includes Host.search_for('compliant != false'), @host1
    end

    should 'be able to filter by "has test results"' do
      assert @host1.test_results.present?
      assert @host2.test_results.empty?
      assert_includes Host.search_for('has_test_results = true'), @host1
      assert_includes Host.with_test_results, @host1
      assert_not_includes(Host.search_for('has_test_results = true'),
                          @host2)
      assert_not_includes Host.with_test_results, @host2
      assert_includes Host.search_for('has_test_results = false'), @host2
      assert_includes Host.with_test_results(false), @host2
      assert_not_includes(Host.search_for('has_test_results = false'),
                          @host1)
      assert_not_includes(Host.with_test_results(false), @host1)
    end

    should 'be able to filter by profile_id from test results' do
      assert_includes Host.search_for("profile_id = #{@profile.id}"),
                      @host1
    end
  end

  context 'with_policies_or_test_results' do
    should 'return hosts either associated to a policy or with test results' do
      profile = FactoryBot.create(:profile, account: @account)
      tr1 = FactoryBot.create(:test_result, host: @host1, profile: profile)
      tr2 = FactoryBot.create(:test_result, host: @host2, profile: profile)

      assert_equal [tr1], @host1.test_results
      assert_equal [tr2], @host2.test_results
      assert_empty @host1.policies
      assert_empty @host2.policies

      assert_includes Host.with_policies_or_test_results, @host1
      assert_includes Host.with_policies_or_test_results, @host2

      tr2.destroy
      assert_includes Host.with_policies_or_test_results, @host1
      assert_not_includes Host.with_policies_or_test_results, @host2

      profile.policy.update!(hosts: [@host2])
      assert_includes Host.with_policies_or_test_results, @host2
      assert_includes Host.with_policies_or_test_results, @host1

      tr1.destroy
      assert_not_includes Host.with_policies_or_test_results, @host1
      assert_includes Host.with_policies_or_test_results, @host2
    end
  end

  context 'scope search by a policy' do
    setup do
      @profile = FactoryBot.create(
        :profile,
        :with_rules,
        rule_count: 2,
        account: @account
      )

      @profile.policy.update(hosts: [@host1])
    end

    should 'find host using assigned policy id' do
      search = "policy_id = #{@profile.policy.id}"
      assert_includes Host.search_for(search), @host1
    end

    should 'find host using a profile id assigned to the policy' do
      search = "policy_id = #{@profile.id}"
      assert_includes Host.search_for(search), @host1
    end

    should 'find host using external profile id from its test result' do
      tr = FactoryBot.create(:test_result, host: @host1, profile: @profile)

      %w[pass fail].each_with_index do |status, idx|
        FactoryBot.create(
          :rule_result,
          host: @host1,
          test_result: tr,
          rule: @profile.rules[idx],
          result: status
        )
      end

      search = "policy_id = #{@profile.policy.id}"
      assert_includes Host.search_for(search), @host1
    end

    should 'NOT find host unassigned to the policy even with test results' do
      pr2 = FactoryBot.create(
        :profile,
        policy: @profile.policy,
        account: @account,
        external: true,
        parent_profile: @profile,
        rules: @profile.rules
      )

      @profile.policy.update(hosts: [])
      tr = FactoryBot.create(:test_result, host: @host1, profile: pr2)

      %w[pass fail].each_with_index do |status, idx|
        FactoryBot.create(
          :rule_result,
          host: @host1,
          test_result: tr,
          rule: pr2.rules[idx],
          result: status
        )
      end

      search = "policy_id = #{pr2.id}"
      assert_not_includes Host.search_for(search), @host1
    end
  end

  context 'scope search for hosts with policy test results' do
    setup do
      @profile = FactoryBot.create(:profile, account: @account)
      @profile.policy.update(hosts: [@host1])
      @tr = FactoryBot.create(:test_result, host: @host1, profile: @profile)
    end

    should 'find host with results using assigned policy id' do
      search = "with_results_for_policy_id = #{@profile.policy.id}"
      assert_includes Host.search_for(search), @host1

      @profile.policy.update!(hosts: [])
      assert_includes Host.search_for(search), @host1

      @tr.update(host: @host2)
      assert_not_includes Host.search_for(search), @host1
    end

    should 'find host using a profile id assigned to the policy' do
      search = "with_results_for_policy_id = #{@profile.id}"
      assert_includes Host.search_for(search), @host1

      @profile.policy.update!(hosts: [])
      assert_includes Host.search_for(search), @host1

      @tr.update!(host: @host2)
      assert_not_includes Host.search_for(search), @host1
    end

    should 'find host using external profile id from its test result' do
      profile = FactoryBot.create(
        :profile,
        account: @account,
        external: true,
        parent_profile: @profile.parent_profile
      )

      FactoryBot.create(
        :test_result,
        profile: profile,
        host: @host1
      )

      search = "with_results_for_policy_id = #{@profile.policy.id}"
      assert_includes Host.search_for(search), @host1

      @profile.policy.update!(hosts: [])
      assert_includes Host.search_for(search), @host1
    end
  end

  test '#os_minor_versions' do
    assert_equal Host.os_minor_versions([@host1]), [4]
  end

  should 'fail if a wrong operator is passed to filter_by_compliance_score' do
    assert_raises(ActiveRecord::StatementInvalid) do
      Host.filter_by_compliance_score(nil, '=\'\' or 1=1);--', 10)
    end
  end
end
