# frozen_string_literal: true

require 'test_helper'

class ProfileHostTest < ActiveSupport::TestCase
  setup do
    @profile = profiles(:one)
    @host = hosts(:one)
    @profile_host = ProfileHost.new(profile: @profile, host: @host)
  end
end
