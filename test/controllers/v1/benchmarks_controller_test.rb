# frozen_string_literal: true

require 'test_helper'

module V1
  class BenchmarksControllerTest < ActionDispatch::IntegrationTest
    setup do
      BenchmarksController.any_instance.stubs(:authenticate_user).yields
      User.current = FactoryBot.create(:user)
    end

    test '#index success' do
      get v1_benchmarks_url
      assert_response :success
    end

    test '#show success' do
      get v1_benchmarks_url(FactoryBot.create(:benchmark))
      assert_response :success
    end
  end
end
