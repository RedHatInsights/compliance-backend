# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200417175851_add_unique_index_to_rule_results'
require 'sidekiq/testing'

class DuplicateRuleResultResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      ActiveRecord::Migration.suppress_messages do
        AddUniqueIndexToRuleResults.new.down
      end
    rescue ArgumentError # if index doesn't exist
    end
    # rubocop:enable Lint/SuppressedException

    User.current = FactoryBot.create(:user)
    rr = FactoryBot.create(:rule_result)
    User.current = nil

    assert_difference('RuleResult.count' => 1) do
      (@dup_result = rr.dup).save(validate: false)
    end
  end

  test 'resolves identical rule results' do
    assert_difference('RuleResult.count' => -1) do
      DuplicateRuleResultResolver.run!
    end
  end
end
