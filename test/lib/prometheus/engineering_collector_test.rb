# frozen_string_literal: true

require 'test_helper'
require 'prometheus_exporter/server'
require 'prometheus/engineering_collector'

class EngineeringCollectorTest < ActiveSupport::TestCase
  setup do
    @collector = EngineeringCollector.new
  end

  test 'metrics' do
    FactoryBot.create(:account)

    assert_nothing_raised do
      metrics = @collector.metrics.map do |metric|
        [metric.name, metric.data.values.first]
      end.to_h

      assert_equal 1, metrics['dangling_accounts']
      assert_equal 0, metrics['dangling_test_results']
      assert_equal 0, metrics['dangling_rule_results']
      assert_equal 0, metrics['dangling_policy_hosts']
    end
  end
end
