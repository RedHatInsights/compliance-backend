# frozen_string_literal: true

require 'test_helper'

class OrphanedLinksRemoverTest < ActiveSupport::TestCase
  setup do
    User.current = FactoryBot.create(:user)

    @profile = FactoryBot.create(:canonical_profile, :with_rules)
    @rr = FactoryBot.create(:rule_result)
    @tr = FactoryBot.create(:test_result)

    # Control group
    FactoryBot.create(:canonical_profile)
    FactoryBot.create(:rule_result)
    FactoryBot.create(:test_result)

    User.current = nil
  end

  test 'removes ProfileRule links for dead profiles' do
    rule = @profile.rules.sample
    p2 = FactoryBot.create(:canonical_profile)

    rule.profiles = [p2]
    p2.delete

    assert_not_empty ProfileRule.where(rule: rule)

    assert_difference('ProfileRule.count' => -1) do
      OrphanedLinksRemover.run!
    end

    assert_empty ProfileRule.where(rule_id: rule.id)
  end

  test 'removes ProfileRule links for dead rules' do
    rules = @profile.rules
    @profile.delete

    assert_not_empty ProfileRule.where(rule: rules)

    assert_difference('ProfileRule.count' => -5) do
      OrphanedLinksRemover.run!
    end

    assert_empty ProfileRule.where(rule: rules)
  end

  test 'removes RuleResult records for dead profiles' do
    @rr.rule.rule_references_container.delete
    @rr.rule.delete

    assert_not_empty RuleResult.where(id: @rr.id)

    assert_difference('RuleResult.count' => -1) do
      OrphanedLinksRemover.run!
    end

    assert_empty ProfileRule.where(id: @rr.id)
  end

  test 'removes RuleResult records for dead hosts' do
    WHost.where(id: @rr.host.id).delete_all

    assert_not_empty RuleResult.where(id: @rr.id)

    assert_difference('RuleResult.count' => -1) do
      OrphanedLinksRemover.run!
    end

    assert_empty RuleResult.where(id: @rr.id)
  end

  test 'removes TestResult records for dead profiles' do
    @tr.profile.delete

    assert_not_empty TestResult.where(id: @tr.id)

    assert_difference('TestResult.count' => -1) do
      OrphanedLinksRemover.run!
    end

    assert_empty TestResult.where(id: @tr.id)
  end

  test 'removes TestResult records for dead hosts' do
    WHost.where(id: @tr.host.id).delete_all

    assert_not_empty TestResult.where(id: @tr.id)

    assert_difference('TestResult.count' => -1) do
      OrphanedLinksRemover.run!
    end

    assert_empty TestResult.where(id: @tr.id)
  end
end
