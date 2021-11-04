# frozen_string_literal: true

require 'test_helper'

class UpstreamProfileRemoverTest < ActiveSupport::TestCase
  setup do
    @account = FactoryBot.create(:account)
    @parent = FactoryBot.create(:canonical_profile, upstream: true)
    @upstream = FactoryBot.create(
      :profile,
      account: @account,
      parent_profile: @parent
    )
    @downstream = FactoryBot.create(:profile, account: @account)
  end

  test 'removes upstream non-canonical profiles' do
    host = FactoryBot.create(:host, account: @account.account_number)
    FactoryBot.create(:test_result, profile: @upstream, host: host)
    FactoryBot.create(:test_result, profile: @downstream, host: host)

    assert_difference(
      '@downstream.test_results.count' => 0,
      '@upstream.test_results.count' => -1,
      'Profile.canonical(false).count' => -1,
      'Policy.count' => -1
    ) do
      UpstreamProfileRemover.run!
    end

    assert_not Profile.exists?(@upstream.id)
  end
end
