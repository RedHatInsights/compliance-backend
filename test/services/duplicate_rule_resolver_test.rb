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

    @rule = FactoryBot.create(:rule)

    assert_difference('Rule.count' => 1) do
      (@dup_rule = @rule.dup).save(validate: false)
    end
  end

  test 'resolves identical rules' do
    assert_difference('Rule.count' => -1) do
      DuplicateRuleResolver.run!
    end
  end

  test 'resolves profile_rules from a duplicate rule with ' \
       'different profiles' do
    p1 = FactoryBot.create(:canonical_profile)
    p2 = FactoryBot.create(:canonical_profile)

    assert_difference('ProfileRule.count' => 2) do
      @rule.profiles << p1
      @dup_rule.profiles << p2
    end

    assert_difference('ProfileRule.count' => 0) do
      DuplicateRuleResolver.run!
    end
  end

  test 'resolves profile_rules from a duplicate rule with ' \
       'the same profiles' do
    profile = FactoryBot.create(:canonical_profile)

    assert_difference('ProfileRule.count' => 2) do
      @rule.profiles << profile
      @dup_rule.profiles << profile
    end

    assert_difference('ProfileRule.count' => -1) do
      DuplicateRuleResolver.run!
    end
  end

  test 'resolves rule_results from a duplicate rule' do
    account = FactoryBot.create(:account)
    host1 = FactoryBot.create(:host, org_id: account.org_id)
    host2 = FactoryBot.create(
      :host,
      org_id: FactoryBot.create(:account).org_id
    )
    profile = FactoryBot.create(
      :profile,
      :with_rules,
      rule_count: 1,
      account: account
    )
    test_result1 = FactoryBot.create(
      :test_result,
      host: host1,
      profile: profile
    )
    test_result2 = FactoryBot.create(
      :test_result,
      host: host2,
      profile: profile
    )

    rule_result = FactoryBot.create(
      :rule_result,
      host: host1,
      test_result: test_result1,
      rule: profile.rules.first
    )

    assert_difference('RuleResult.count' => 2) do
      rule_result.dup.update!(rule: profile.rules.first, host: host2,
                              test_result: test_result2)
      rule_result.dup.update!(rule: @dup_rule, host: host2)
    end

    assert_difference('RuleResult.count' => 0) do
      DuplicateRuleResolver.run!
    end
  end
end
