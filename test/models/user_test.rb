# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  should validate_uniqueness_of :redhat_id
  should validate_uniqueness_of :login
  should validate_presence_of :redhat_id
  should validate_presence_of :login
end
