# frozen_string_literal: true

require 'test_helper'

class BusinessObjectiveTest < ActiveSupport::TestCase
  should have_many :profiles
  should validate_presence_of :title
end
