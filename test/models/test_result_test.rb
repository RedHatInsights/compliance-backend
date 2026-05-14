# frozen_string_literal: true

require 'test_helper'

class TestResultTest < ActiveSupport::TestCase
  # Setup hack to go around the missing chain of created records which V2 TestResults require
  setup do
    User.current = FactoryBot.create(:user)
  end

  subject { FactoryBot.create(:test_result) }

  should have_one(:benchmark).through(:profile)
  should have_many(:rule_results).dependent(:delete_all)
  should belong_to(:profile)
  should validate_presence_of(:host).on(:create)
  should validate_presence_of(:profile)
  should validate_presence_of(:end_time)
  should validate_uniqueness_of(:end_time).scoped_to(%i[host_id profile_id])
end
