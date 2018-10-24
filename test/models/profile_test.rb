# frozen_string_literal: true

require 'test_helper'

class ProfileTest < ActiveSupport::TestCase
  should validate_uniqueness_of :ref_id
  should validate_presence_of :ref_id
  should validate_presence_of :name
end
