# frozen_string_literal: true

require 'test_helper'

module V1
  class SupportedSsgsControllerTest < ActionDispatch::IntegrationTest
    setup do
      SupportedSsgsController.any_instance.stubs(:authenticate_user).yields
      @hosts = FactoryBot.create_list(:host, 2)
      stub_supported_ssg(@hosts)
    end

    context 'index' do
      should 'lists all supported SSGs' do
        get v1_supported_ssgs_url

        assert_response :success
      end
    end
  end
end
