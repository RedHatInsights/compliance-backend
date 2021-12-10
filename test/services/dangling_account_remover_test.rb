# frozen_string_literal: true

require 'test_helper'

class DanglingAccountRemoverTest < ActiveSupport::TestCase
  test 'removes accounts that have no relationships' do
    FactoryBot.create_list(:account, 30)

    assert_difference('Account.count' => -30) do
      DanglingAccountRemover.run!
    end
  end

  test 'keeps accounts that have relationships' do
    accounts = FactoryBot.create_list(:account, 5)
    FactoryBot.create(:user, account: accounts[4])
    host1 = FactoryBot.create(:host, account: accounts[0].account_number)
    host2 = FactoryBot.create(:host, account: accounts[1].account_number)

    profile1 = FactoryBot.create(:profile, account: accounts[0])
    profile1.policy.update(hosts: [host1])

    profile2 = FactoryBot.create(:profile, account: accounts[1])
    FactoryBot.create(:test_result, profile: profile2, host: host2)

    FactoryBot.create(:policy, account: accounts[2])
    FactoryBot.create(:profile, account: accounts[3], policy: nil)

    assert_difference('Account.count' => -1, 'User.count' => -1) do
      DanglingAccountRemover.run!
    end

    assert accounts[0].reload
    assert accounts[1].reload
    assert accounts[2].reload
    assert accounts[3].reload
  end

  test 'accounts_with_hosts' do
    ApplicationRecord.connection.expects(:data_source_exists?).returns(false)
    none = DanglingAccountRemover.send(:accounts_with_hosts)
    assert none, ApplicationRecord.none
  end
end
