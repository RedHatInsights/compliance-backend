# frozen_string_literal: true

require 'test_helper'

class BenchmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    BenchmarksController.any_instance.stubs(:authenticate_user)
    User.current = users(:test)
    users(:test).update! account: accounts(:test)
  end

  test '#index success' do
    get benchmarks_url
    assert_response :success
  end

  test '#show success' do
    get benchmarks_url(benchmarks(:one))
    assert_response :success
  end
end
