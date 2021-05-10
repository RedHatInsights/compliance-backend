# frozen_string_literal: true

require 'test_helper'

class BenchmarkPolicyTest < ActiveSupport::TestCase
  test 'all benchmarks are accessible' do
    user = FactoryBot.create(:user)
    profile = FactoryBot.create(:canonical_profile)

    assert_equal Xccdf::Benchmark.all,
                 Pundit.policy_scope(user, Xccdf::Benchmark)
    assert Pundit.authorize(user, profile, :index?)
    assert Pundit.authorize(user, profile, :show?)
  end
end
