# frozen_string_literal: true

require 'test_helper'

module V1
  class OpenapiEndpointTest < ActionDispatch::IntegrationTest
    test 'openapi v1 success' do
      User.current = nil
      assert_nil User.current
      get '/api/compliance/v1/openapi.json'
      assert_response :success
    end
  end
end
