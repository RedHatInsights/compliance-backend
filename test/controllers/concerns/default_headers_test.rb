# frozen_string_literal: true

require 'test_helper'

class DefaultHeadersTest < ActionDispatch::IntegrationTest
  setup do
    ApplicationController.any_instance.expects(:authenticate_user).yields
    ApplicationController.any_instance.stubs(:index).returns('Response Body')
    Rails.application.routes.draw do
      root 'application#index'
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test 'response includes default headers' do
    get '/'
    default_headers = Rails.application.config
                           .action_dispatch.default_headers
                           .keys.to_set
    assert default_headers.subset?(response.header.keys.to_set)
  end
end
