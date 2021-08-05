# frozen_string_literal: true

require 'test_helper'
require 'prometheus_exporter/server'
require 'prometheus/business_collector'

class BusinessCollectorTest < ActiveSupport::TestCase
  setup do
    @collector = BusinessCollector.new
  end

  test 'metrics' do
    account, = FactoryBot.create_list(:account, 3)
    FactoryBot.create_list(
      :host,
      2,
      account: account.account_number,
      policies: [FactoryBot.create(:policy, account: account)]
    )

    policy = FactoryBot.create(:policy, account: account)
    FactoryBot.create(:profile, policy: policy, account: account)
    FactoryBot.create_list(
      :host,
      50,
      account: account.account_number,
      policies: [policy]
    )

    assert_nothing_raised do
      metrics = @collector.metrics.map do |metric|
        if metric.data.key?({}) # it's a gauge
          [metric.name, metric.data[{}]]
        else # it's a counter
          [
            metric.name,
            metric.data.each_with_object({}) do |(key, value), obj|
              obj[key[:version]] = value
            end
          ]
        end
      end.to_h

      assert_equal 3, metrics['total_accounts']
      assert_equal 0, metrics['client_accounts']
      assert_equal 0, metrics['client_accounts_with_hosts']
      assert_equal 1, metrics['total_accounts_with_50plus_hosts_per_policy']
      assert_equal 0, metrics['client_accounts_with_50plus_hosts_per_policy']
      assert_equal 2, metrics['total_policies']
      assert_equal 0, metrics['client_policies']
      assert_equal 1, metrics['total_policies_by_os_major']['7']
      assert_nil metrics['client_policies_by_os_major']['7']
      assert_equal 1, metrics['total_50plus_policies']
      assert_equal 0, metrics['client_50plus_policies']
      assert_equal 52, metrics['total_systems']
      assert_equal 0, metrics['client_systems']
      assert_equal 52, metrics['total_systems_by_os']['7.9']
      assert_nil metrics['client_systems_by_os']['7.9']
    end
  end
end
