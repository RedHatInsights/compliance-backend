# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20210809071351_deduplicate_accounts.rb'

class DuplicateAccountResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      ActiveRecord::Migration.suppress_messages do
        DeduplicateAccounts.new.down
      end
    rescue ArgumentError # if index doesn't exist
    end
    # rubocop:enable Lint/SuppressedException

    @account1 = FactoryBot.create(:account)
    @account1d = FactoryBot.create(
      :account, account_number: @account1.account_number
    )
    @account2 = FactoryBot.create(:account)
    @account2d = FactoryBot.create(
      :account, account_number: @account2.account_number
    )

    Account.find_each do |account|
      FactoryBot.create(:user, account: account)
      policy = FactoryBot.create(:policy, account: account)
      FactoryBot.create(:profile, account: account, policy: policy)
    end
  end

  test 'resolves duplicate accounts' do
    assert_difference('Account.count' => -2) do
      DuplicateAccountResolver.run!
    end
  end

  test 'assigns related entities to the deduplicated accounts' do
    users1 = @account1.users.pluck(:id) + @account1d.users.pluck(:id)
    users2 = @account2.users.pluck(:id) + @account2d.users.pluck(:id)
    profiles1 = @account1.profiles.pluck(:id) + @account1d.profiles.pluck(:id)
    profiles2 = @account2.profiles.pluck(:id) + @account2d.profiles.pluck(:id)
    policies1 = @account1.policies.pluck(:id) + @account1d.policies.pluck(:id)
    policies2 = @account2.policies.pluck(:id) + @account2d.policies.pluck(:id)

    DuplicateAccountResolver.run!

    assert_equal @account1.reload.users.pluck(:id), users1
    assert_equal @account2.reload.users.pluck(:id), users2
    assert_equal @account1.reload.profiles.pluck(:id), profiles1
    assert_equal @account2.reload.profiles.pluck(:id), profiles2
    assert_equal @account1.reload.policies.pluck(:id), policies1
    assert_equal @account2.reload.policies.pluck(:id), policies2
  end
end
