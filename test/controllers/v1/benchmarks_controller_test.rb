# frozen_string_literal: true

require 'test_helper'

module V1
  class BenchmarksControllerTest < ActionDispatch::IntegrationTest
    setup do
      ::BenchmarksController.any_instance.stubs(:authenticate_user)
      User.current = users(:test)
      users(:test).update! account: accounts(:test)
    end

    test '#index success' do
      get v1_benchmarks_url
      assert_response :success
    end

    test '#show success' do
      get v1_benchmarks_url(benchmarks(:one))
      assert_response :success
    end
  end
end
