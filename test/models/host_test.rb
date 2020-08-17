# frozen_string_literal: true

require 'test_helper'

class HostTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_presence_of :account

  setup do
    users(:test).account = accounts(:test)
    User.current = users(:test)

    mock_platform_api
  end

  test 'compliant returns a hash with all compliance statuses' do
    host = hosts(:one)
    host.profiles << [profiles(:one), profiles(:two)]
    expected_result = {
      profiles(:one).ref_id.to_s => false,
      profiles(:two).ref_id.to_s => false
    }
    assert_equal expected_result, host.compliant
  end

  context 'external methods for search' do
    setup do
      @host = hosts(:one)
      @host.profiles << profiles(:one)
      rules(:one).profiles << profiles(:one)
      rules(:two).profiles << profiles(:one)
      test_results(:one).update(host: hosts(:one), profile: profiles(:one))
      RuleResult.create(host: @host, rule: rules(:one),
                        test_result: test_results(:one), result: 'pass')
      RuleResult.create(host: @host, rule: rules(:two),
                        test_result: test_results(:one), result: 'fail')
    end

    should 'total_rules returns the number of rules' do
      assert_equal 2, @host.last_scan_results.count
    end

    should 'rules_passed returns the number of rules that passed' do
      assert_equal 1, @host.rules_passed
    end

    should 'rules_failed returns the number of rules that failed' do
      assert_equal 1, @host.rules_failed
    end

    should 'compliance_score returns the percentage of rules that passed' do
      assert_equal 50.0, @host.compliance_score
    end

    should 'be able to find based on compliance score' do
      assert_includes(
        Host.search_for('compliance_score >= 40 and compliance_score <= 60'),
        hosts(:one)
      )
      assert_not_includes(
        Host.search_for('compliance_score >= 0 and compliance_score <= 39'),
        hosts(:one)
      )
    end

    should 'be able to find based on compliance true/false' do
      assert_not_includes Host.search_for('compliant = true'), hosts(:one)
      assert_includes Host.search_for('compliant = false'), hosts(:one)
      assert_includes Host.search_for('compliant != true'), hosts(:one)
      assert_not_includes Host.search_for('compliant != false'), hosts(:one)
    end

    should 'be able to filter by "has test results"' do
      hosts(:two).test_results.destroy_all
      assert hosts(:one).test_results.present?
      assert hosts(:two).test_results.empty?
      assert_includes Host.search_for('has_test_results = true'), hosts(:one)
      assert_not_includes(Host.search_for('has_test_results = true'),
                          hosts(:two))
      assert_includes Host.search_for('has_test_results = false'), hosts(:two)
      assert_not_includes(Host.search_for('has_test_results = false'),
                          hosts(:one))
    end
  end

  context '.find_or_create_hosts_by_inventory_ids' do
    setup do
      Host.destroy_all
    end

    should 'return an array of hosts' do
      host_ids = %w[ID1 ID2 ID3]
      assert Host.find_or_create_hosts_by_inventory_ids(host_ids)[0].class, Host
    end

    should 'creates new hosts if needed' do
      host_ids = %w[ID1 ID2 ID3]
      assert_difference('Host.count', host_ids.size) do
        Host.find_or_create_hosts_by_inventory_ids(host_ids)
      end
    end
  end
end
