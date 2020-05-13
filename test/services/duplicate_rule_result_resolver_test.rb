# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200417175851_add_unique_index_to_rule_results'
require 'sidekiq/testing'

class DuplicateRuleResultResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      AddUniqueIndexToRuleResults.new.down
    rescue ArgumentError # if index doesn't exist
    end
    # rubocop:enable Lint/SuppressedException

    assert_difference('RuleResult.count' => 1) do
      (@dup_result = rule_results(:one).dup).save(validate: false)
    end
  end

  test 'resolves identical rule results' do
    assert_difference('RuleResult.count' => -1) do
      DuplicateRuleResultResolver.run!
    end
  end
end
