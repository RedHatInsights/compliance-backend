# frozen_string_literal: true

require 'test_helper'
require 'rake'

class CleanupDbTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'cleanup_db removes dangling records' do
    account = FactoryBot.create(:account)
    FactoryBot.create(:host, account: account.account_number)
    policy = FactoryBot.create(:policy, account: account)
    account.dup.update!(account_number: '8675309')

    TestResult.new(host_id: UUID.generate).save(validate: false)
    RuleResult.new(host_id: UUID.generate).save(validate: false)
    PolicyHost.new(host_id: UUID.generate, policy: policy)
              .save(validate: false)

    assert_difference(
      'Account.count' => -1,
      'TestResult.count' => -1, 'RuleResult.count' => -1,
      'PolicyHost.count' => -1
    ) do
      capture_io do
        Rake::Task['cleanup_db'].execute
      end
    end
  end

  test 'cleanup_db does not remove accounts on a profile, policy, or host' do
    aorig = FactoryBot.create(:account)
    FactoryBot.create(:host, account: aorig.account_number)
    (account = aorig.dup).update!(account_number: '9797979')
    FactoryBot.create(:profile, account: account)
    (account = aorig.dup).update!(account_number: '3213213')
    FactoryBot.create(:policy, account: account)
    assert_difference('Account.count' => 0) do
      capture_io do
        Rake::Task['cleanup_db'].execute
      end
    end
  end
end
