# frozen_string_literal: true

require 'test_helper'

class HostTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of(:name).scoped_to(:account_id)
end
