# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200417180344_add_unique_index_to_test_results'
require 'sidekiq/testing'

class DuplicateTestResultResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      AddUniqueIndexToTestResults.new.down
    rescue ArgumentError # if index doesn't exist
    end
    # rubocop:enable Lint/SuppressedException

    assert_difference('TestResult.count' => 1) do
      (@dup_result = test_results(:one).dup).save(validate: false)
    end
  end

  test 'resolves identical test results' do
    assert_difference('TestResult.count' => -1) do
      DuplicateTestResultResolver.run!
    end
  end

  test 'resolves identical rule results of identical test results' do
    assert_difference('RuleResult.count' => 1) do
      rule_results(:one).dup.update!(test_result: @dup_result)
    end

    assert_difference('RuleResult.count' => -1) do
      DuplicateTestResultResolver.run!
    end
  end

  test 'resolves different rule results of identical test results' do
    assert_difference('RuleResult.count' => 1) do
      rule_results(:two).dup.update!(test_result: @dup_result)
    end

    assert_difference('RuleResult.count' => 0) do
      DuplicateTestResultResolver.run!
    end
  end
end
