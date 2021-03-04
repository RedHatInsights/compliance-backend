# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200415201445_add_unique_index_to_rules.rb'

class DuplicateRuleResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      ActiveRecord::Migration.suppress_messages do
        AddUniqueIndexToRules.new.down
      end
    rescue ArgumentError # if index doesn't exist
    end
    # rubocop:enable Lint/SuppressedException

    assert_difference('Rule.count' => 1) do
      (@dup_rule = rules(:one).dup).save(validate: false)
    end
  end

  test 'resolves identical rules' do
    assert_difference('Rule.count' => -1) do
      DuplicateRuleResolver.run!
    end
  end

  test 'resolves profile_rules from a duplicate rule with '\
       'different profiles' do
    assert_difference('ProfileRule.count' => 2) do
      rules(:one).profiles << profiles(:one)
      @dup_rule.profiles << profiles(:two)
    end

    assert_difference('ProfileRule.count' => 0) do
      DuplicateRuleResolver.run!
    end
  end

  test 'resolves profile_rules from a duplicate rule with '\
       'the same profiles' do
    assert_difference('ProfileRule.count' => 2) do
      rules(:one).profiles << profiles(:two)
      @dup_rule.profiles << profiles(:two)
    end

    assert_difference('ProfileRule.count' => -1) do
      DuplicateRuleResolver.run!
    end
  end

  test 'resolves rule_results from a duplicate rule' do
    assert_difference('RuleResult.count' => 2) do
      rule_results(:one).dup.update!(rule: rules(:one), host: hosts(:two),
                                     test_result: test_results(:two))
      rule_results(:one).dup.update!(rule: @dup_rule, host: hosts(:two))
    end

    assert_difference('RuleResult.count' => 0) do
      DuplicateRuleResolver.run!
    end
  end
end
