# frozen_string_literal: true

require 'test_helper'

class PolicyHostTest < ActiveSupport::TestCase
  should belong_to(:policy)
  should validate_presence_of(:host)
end
