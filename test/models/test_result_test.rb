# frozen_string_literal: true

require 'test_helper'

class TestResultTest < ActiveSupport::TestCase
  should have_one(:benchmark).through(:profile)
  should have_many(:rule_results).dependent(:delete_all)
  should belong_to(:profile)
  should validate_presence_of(:host)
  should validate_presence_of(:profile)
  should validate_presence_of(:end_time)
  should validate_uniqueness_of(:end_time).scoped_to(%i[host_id profile_id])
end
