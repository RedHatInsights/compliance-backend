# frozen_string_literal: true

require 'test_helper'

class RuleReferencesContainerTest < ActiveSupport::TestCase
  should belong_to(:rule)
end
