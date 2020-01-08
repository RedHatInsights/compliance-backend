# frozen_string_literal: true

require 'test_helper'

class TestResultTest < ActiveSupport::TestCase
  should have_one(:benchmark).through(:profile)
  should have_many(:rule_results).dependent(:delete_all)
  should belong_to(:profile)
  should belong_to(:host)
  should validate_presence_of(:host_id)
  should validate_presence_of(:profile_id)
end
