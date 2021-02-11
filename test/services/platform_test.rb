# frozen_string_literal: true

require 'test_helper'

class PlatformServiceTest < ActiveSupport::TestCase
  test 'basic auth' do
    basic_auth = %w[username pass]
    ::Platform.stubs(:BASIC_AUTH).returns(basic_auth) do
      Faraday.any_instance.expects(:basic_auth).with(*basic_auth).at_least_once
      Platform.connection
    end
  end
end
