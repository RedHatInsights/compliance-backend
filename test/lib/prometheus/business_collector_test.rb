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

    assert_nothing_raised do
      metrics = @collector.metrics.map do |metric|
        [metric.name, metric.data.values.first]
      end.to_h

      assert_equal 3, metrics['total_accounts']
      assert_equal 0, metrics['client_accounts']
      assert_equal 0, metrics['client_accounts_with_hosts']
      assert_equal 0, metrics['total_policies']
      assert_equal 0, metrics['client_policies']
      assert_equal 2, metrics['total_systems']
      assert_equal 0, metrics['client_systems']
    end
  end
end
