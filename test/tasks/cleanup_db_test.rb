# frozen_string_literal: true

require 'test_helper'
require 'rake'

class CleanupDbTest < ActiveSupport::TestCase
  test 'cleanup_db removes dangling records' do
    accounts(:one).dup.update!(account_number: '8675309')
    TestResult.new(host_id: UUID.generate).save(validate: false)
    RuleResult.new(host_id: UUID.generate).save(validate: false)
    PolicyHost.new(host_id: UUID.generate, policy: policies(:one))
              .save(validate: false)

    assert_difference(
      'Account.count' => -1,
      'TestResult.count' => -1, 'RuleResult.count' => -1,
      'PolicyHost.count' => -1
    ) do
      Rake::Task['cleanup_db'].execute
    end
  end

  test 'cleanup_db does not remove accounts on a profile, policy, or host' do
    (account = accounts(:one).dup).update!(account_number: '9797979')
    profiles(:one).update!(account: account)
    (account = accounts(:one).dup).update!(account_number: '3213213')
    policies(:one).update!(account: account)
    accounts(:one).dup.update!(account_number: hosts(:one).account_number)
    assert_difference('Account.count' => 0) do
      Rake::Task['cleanup_db'].execute
    end
  end
end
