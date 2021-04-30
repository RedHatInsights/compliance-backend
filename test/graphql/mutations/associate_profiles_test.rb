# frozen_string_literal: true

require 'test_helper'

class AssociateProfilesMutationTest < ActiveSupport::TestCase
  QUERY = <<-GRAPHQL
     mutation associateProfiles($input: associateProfilesInput!) {
        associateProfiles(input: $input) {
           system {
               id
               name
           }
        }
     }
  GRAPHQL

  setup do
    @user = FactoryBot.create(:user)
    @profiles = FactoryBot.create_list(:profile, 2, account: @user.account)
    @host = FactoryBot.create(:host, account: @user.account.account_number)
  end

  test 'provide all required arguments' do
    assert_empty @host.policies

    Schema.execute(
      QUERY,
      variables: { input: {
        id: @host.id,
        profileIds: @profiles.map(&:id)
      } },
      context: { current_user: @user }
    )['data']['associateProfiles']['system']

    assert_equal Set.new(@host.reload.policies),
                 Set.new(@profiles.map(&:policy))
  end

  test 'external profiles are kept after associating internal profiles' do
    Schema.execute(
      QUERY,
      variables: { input: {
        id: @host.id,
        profileIds: @profiles.map(&:id)
      } },
      context: { current_user: @user }
    )['data']['associateProfiles']['system']

    assert_equal Set.new(@profiles.map(&:policy)),
                 Set.new(@host.reload.policies)
    assert_audited 'Associated host'
    assert_audited @host.id
    @profiles.each do |profile|
      assert_audited profile.policy.id
    end
  end
end
