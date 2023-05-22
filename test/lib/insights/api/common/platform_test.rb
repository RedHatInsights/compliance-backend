# frozen_string_literal: true

require 'test_helper'

module Insights
  module Api
    module Common
      class PlatformTest < ActiveSupport::TestCase
        test 'returns faraday connection object' do
          assert_instance_of(Faraday::Connection, Platform.connection)
        end

        test 'basic auth' do
          basic_auth = %w[username pass]
          Platform.stubs(:BASIC_AUTH).returns(basic_auth) do
            Faraday.any_instance.expects(:basic_auth).with(*basic_auth).at_least_once
            Platform.connection
          end
        end
      end
    end
  end
end
