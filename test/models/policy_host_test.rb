# frozen_string_literal: true

require 'test_helper'

class PolicyHostTest < ActiveSupport::TestCase
  should belong_to(:policy)
  should validate_presence_of(:host)

  setup do
    @account = FactoryBot.create(:user).account
    v1 = SupportedSsg.by_os_major['7'].first
    bm1 = FactoryBot.create(
      :benchmark,
      version: v1.version,
      os_major_version: '7'
    )

    v2 = SupportedSsg.by_os_major['7'].last
    bm2 = FactoryBot.create(
      :benchmark,
      version: v2.version,
      os_major_version: '7'
    )

    @policy1 = FactoryBot.create(:policy, account: @account)
    @policy2 = FactoryBot.create(:policy, account: @account)
    @p1 = FactoryBot.create(:canonical_profile, upstream: false, policy: @policy1, benchmark: bm1)
    @p2 = FactoryBot.create(:canonical_profile, upstream: false, policy: @policy2, benchmark: bm2)
    @host1 = Host.find(FactoryBot.create(
      :host,
      account: @account.account_number,
      os_major_version: 7,
      os_minor_version: 1
    ).id)

    @host2 = Host.find(FactoryBot.create(
      :host,
      account: @account.account_number,
      os_major_version: 8,
      os_minor_version: 3
    ).id)
  end

  test 'an unsupported host based on minor version cannot be assigned to a policy' do
    exception = assert_raises(Exception) do
      @policy2.hosts << @host1
    end
    assert_equal(exception.message, 'Validation failed: Host os version is unsupported for this policy')
  end

  test 'an unsupported host based on major version cannot be assigned to a policy' do
    exception = assert_raises(Exception) do
      @policy1.hosts << @host2
    end
    assert_equal(exception.message, 'Validation failed: Host os version is unsupported for this policy')
  end

  test 'a supported host can be assigned to a policy' do
    assert_nothing_raised do
      @policy1.hosts << @host1
    end
  end
end
