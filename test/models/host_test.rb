# frozen_string_literal: true

require 'test_helper'

class HostTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of(:name).scoped_to(:account_id)

  test 'compliant returns a hash with all compliance statuses' do
    host = hosts(:one)
    host.profiles << [profiles(:one), profiles(:two)]
    expected_result = {
      profiles(:one).ref_id.to_s => false,
      profiles(:two).ref_id.to_s => false
    }
    assert_equal expected_result, host.compliant
  end
end
