# frozen_string_literal: true

require 'test_helper'

class RuleResultTest < ActiveSupport::TestCase
  should validate_presence_of :rule
  should validate_presence_of :host
  should validate_presence_of :test_result
end
