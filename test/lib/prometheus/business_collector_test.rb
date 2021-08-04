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
    FactoryBot.create_list(
      :host,
      50,
      account: account.account_number,
      policies: [policy]
    )

    profile = FactoryBot.create(:profile, policy: policy, account: account)
    FactoryBot.create(:test_result, profile: profile, host: policy.hosts.first)

    assert_nothing_raised do
      metrics = @collector.metrics.map do |metric|
        if metric.data.key?({})
          [metric.name, metric.data[{}]]
        else
          [
            metric.name,
            metric.data.each_with_object({}) do |(key, value), obj|
              if key.key?(:version)
                obj[key[:version]] = value
              elsif key.key?(:month)
                obj[[key[:year], key[:month]].join('.')] = value
              end
            end
          ]
        end
      end.to_h

      month = [Time.zone.now.year, Time.zone.now.month].join('.')

      assert_equal 3, metrics['total_accounts']
      assert_equal 0, metrics['client_accounts']
      assert_equal 0, metrics['client_accounts_with_hosts']
      assert_equal 1, metrics['total_accounts_with_50plus_hosts_per_policy']
      assert_equal 0, metrics['client_accounts_with_50plus_hosts_per_policy']
      assert_equal 2, metrics['total_policies']
      assert_equal 0, metrics['client_policies']
      assert_equal 1, metrics['total_50plus_policies']
      assert_equal 0, metrics['client_50plus_policies']
      assert_equal 52, metrics['total_systems']
      assert_equal 0, metrics['client_systems']
      assert_equal 52, metrics['total_systems_by_os']['7.9']
      assert_nil metrics['client_systems_by_os']['7.9']
      assert_equal 1, metrics['total_reports_per_month'][month]
      assert_equal 0, metrics['client_reports_per_month'][month]
    end
  end
end
