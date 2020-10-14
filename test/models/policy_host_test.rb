# frozen_string_literal: true

require 'test_helper'

class PolicyHostTest < ActiveSupport::TestCase
  should belong_to(:policy)
  should belong_to(:host)
end
