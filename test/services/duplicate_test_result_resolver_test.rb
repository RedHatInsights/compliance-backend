# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200417180344_add_unique_index_to_test_results'
require 'sidekiq/testing'

class DuplicateTestResultResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.suppress_messages do
          AddUniqueIndexToTestResults.new.down
        end
      end
    rescue ArgumentError # if index doesn't exist
    end
    # rubocop:enable Lint/SuppressedException

    User.current = FactoryBot.create(:user)
    @rr1 = FactoryBot.create(:rule_result)
    @rr2 = FactoryBot.create(:rule_result)
    User.current = nil

    assert_difference('TestResult.count' => 1) do
      (@dup_result = @rr1.test_result.dup).save(validate: false)
    end
  end

  test 'resolves identical test results' do
    assert_difference('TestResult.count' => -1) do
      DuplicateTestResultResolver.run!
    end
  end

  test 'resolves identical rule results of identical test results' do
    assert_difference('RuleResult.count' => 1) do
      @rr1.dup.update!(test_result: @dup_result)
    end

    assert_difference('RuleResult.count' => -1) do
      DuplicateTestResultResolver.run!
    end
  end

  test 'resolves different rule results of identical test results' do
    assert_difference('RuleResult.count' => 1) do
      @rr2.dup.update!(test_result: @dup_result)
    end

    assert_difference('RuleResult.count' => 0) do
      DuplicateTestResultResolver.run!
    end
  end
end
