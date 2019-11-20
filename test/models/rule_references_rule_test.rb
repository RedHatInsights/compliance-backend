# frozen_string_literal: true

require 'test_helper'

# Validations for join model RuleReferenceRule
class RuleReferencesRuleTest < ActiveSupport::TestCase
  should belong_to(:rule)
  should belong_to(:rule_reference)
  should validate_presence_of(:rule)
  should validate_presence_of(:rule_reference)

  test 'validate uniqueness scoped to rule' do
    rules(:one).references << rule_references(:one)
    assert_raises(ActiveRecord::RecordInvalid) do
      rules(:one).references << rule_references(:one)
    end
  end
end
