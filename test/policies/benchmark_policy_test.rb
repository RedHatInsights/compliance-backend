# frozen_string_literal: true

require 'test_helper'

class BenchmarkPolicyTest < ActiveSupport::TestCase
  test 'all benchmarks are accessible' do
    assert_equal Xccdf::Benchmark.all,
                 Pundit.policy_scope(users(:test), Xccdf::Benchmark)
    assert Pundit.authorize(users(:test), profiles(:one), :index?)
    assert Pundit.authorize(users(:test), profiles(:one), :show?)
  end
end
