# frozen_string_literal: true

require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  should have_many :users
  should validate_presence_of :account_number
end
