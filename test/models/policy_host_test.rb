# frozen_string_literal: true

require 'test_helper'

class PolicyHostTest < ActiveSupport::TestCase
  should belong_to(:policy)
  should validate_presence_of(:host)

  setup do
    account = FactoryBot.create(:user).account

    supported_ssg1 = SupportedSsg.new(version: '0.1.50',
                                      os_major_version: '7', os_minor_version: '1')
    supported_ssg2 = SupportedSsg.new(version: '0.1.52',
                                      os_major_version: '7', os_minor_version: '9')

    SupportedSsg.stubs(:all).returns([supported_ssg1, supported_ssg2])

    bm1 = FactoryBot.create(
      :benchmark,
      version: supported_ssg1.version,
      os_major_version: '7'
    )

    bm2 = FactoryBot.create(
      :benchmark,
      version: supported_ssg2.version,
      os_major_version: '7'
    )

    @policy1 = FactoryBot.create(:policy, account: account)
    @policy2 = FactoryBot.create(:policy, account: account)

    FactoryBot.create(:profile, policy: @policy1, account: account, benchmark: bm1)
    FactoryBot.create(:profile, policy: @policy2, account: account, benchmark: bm2)

    @policy1.stubs(:supported_os_minor_versions).returns(['1'])
    @policy2.stubs(:supported_os_minor_versions).returns(['9'])

    @host1 = Host.find(FactoryBot.create(
      :host,
      org_id: account.org_id,
      os_major_version: 7,
      os_minor_version: 1
    ).id)

    @host2 = Host.find(FactoryBot.create(
      :host,
      org_id: account.org_id,
      os_major_version: 8,
      os_minor_version: 3
    ).id)
  end

  test 'an unsupported host based on minor version cannot be assigned to a policy' do
    exception = assert_raises(Exception) do
      @policy2.hosts << @host1
    end
    assert_equal(exception.message, 'Validation failed: Host Unsupported OS minor version')
  end

  test 'an unsupported host based on major version cannot be assigned to a policy' do
    exception = assert_raises(Exception) do
      @policy1.hosts << @host2
    end
    assert_equal(exception.message,
                 'Validation failed: Host Unsupported OS major version')
  end

  test 'a supported host can be assigned to a policy' do
    assert_nothing_raised do
      @policy1.hosts << @host1
    end
  end
end
