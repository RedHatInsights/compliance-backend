# frozen_string_literal: true

require 'test_helper'

class CopyValueOverridesToNonCanonicalTest < ActiveSupport::TestCase
  setup do
    account = FactoryBot.create(:account)
    value1 = FactoryBot.create(:value_definition)
    value2 = FactoryBot.create(:value_definition)

    @parent1 = FactoryBot.create(:canonical_profile)
    @parent1.update!(value_overrides: { value1.ref_id => 'test', value2.ref_id => 5 })
    FactoryBot.create(:profile, parent_profile: @parent1, account: account)
    FactoryBot.create(:profile, parent_profile: @parent1, account: account)

    @parent2 = FactoryBot.create(:canonical_profile)
    @parent2.update!(value_overrides: { value1.id => 'test2' })
    FactoryBot.create(:profile, parent_profile: @parent2, account: account)
    FactoryBot.create(:profile, parent_profile: @parent2, account: account)

    @parent3 = FactoryBot.create(:canonical_profile)
    @parent3.update!(value_overrides: {})
    FactoryBot.create(:profile, parent_profile: @parent3, account: account)
    FactoryBot.create(:profile, parent_profile: @parent3, account: account)
  end

  test 'correctly copies value overrides from parent profiles to non-canonical profiles' do
    Profile.canonical(false).each do |p|
      assert_equal p.value_overrides, {}
    end

    CopyValueOverridesToNonCanonical.run!

    Profile.canonical(false).each do |p|
      assert_equal p.parent_profile.value_overrides, p.value_overrides
    end
  end
end
