# frozen_string_literal: true

require 'test_helper'
require 'exception_notifier_custom_data'

# This class tests a "dummy" controller for the exception notifier.
class MocksController < ActionController::API
  include ExceptionNotifierCustomData

  def index; end

  def current_user
    :current_user
  end
end

class ExceptionNotifierCustomDataTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.routes.draw { resources :mocks }
  end

  teardown do
    Rails.application.reload_routes!
  end

  test 'adds exception_data to request env' do
    get mocks_path
    assert_response :success
    assert_equal(
      :current_user,
      response.request.env.dig(
        'exception_notifier.exception_data', :current_user
      )
    )
  end
end
