# frozen_string_literal: true

require 'test_helper'

module V1
  # Integration test of the statuses controller
  class StatusesControllerTest < ActionDispatch::IntegrationTest
    class StatusTest < StatusesControllerTest
      test 'success' do
        get status_url
        assert_response :ok
      end

      test 'no active connection' do
        ActiveRecord::Base.stubs(:connection).returns(
          OpenStruct.new(active?: false)
        )

        get status_url
        assert_response :internal_server_error
      end

      test 'database error' do
        ActiveRecord::Base.stubs(:connection).raises(PG::Error)

        get status_url
        assert_response :internal_server_error
      end
    end
  end
end
