# frozen_string_literal: true

require 'test_helper'

class RuleGroupTailoringCopierTest < ActiveSupport::TestCase
  setup do
    account = FactoryBot.create(:account)
    @profile = FactoryBot.create(:canonical_profile, :with_rule_groups)
    FactoryBot.create_list(:profile, 10, account: account, parent_profile: @profile)
  end

  test 'copies rule groups from canonical profiles to non-canonical ones' do
    Profile.canonical(false).each do |profile|
      assert_empty profile.rule_groups
    end

    RuleGroupTailoringCopier.run!

    Profile.canonical(false).each do |profile|
      assert_equal @profile.rule_groups, profile.rule_groups
    end
  end
end
