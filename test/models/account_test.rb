# frozen_string_literal: true

require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  should have_many :users
  should have_many :hosts
  should have_many :profiles
  should have_many :business_objectives
  should validate_presence_of :account_number
end
