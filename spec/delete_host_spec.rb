# frozen_string_literal: true

require 'rails_helper' # spec_helper?
require 'sidekiq/testing'

describe DeleteHost do
  let(:user) { FactoryBot.create(:user) }
  let(:host) { FactoryBot.create(:host, org_id: user.account.org_id) }
  let(:profile) { FactoryBot.create(:profile, :with_rules, account: user.account) }
  let(:message_id) { host.id }
  let(:message) { { 'id' => message_id, 'type' => 'delete' } }
  let!(:test_result) { FactoryBot.create(:test_result, profile: profile, host: host) }
  let!(:rule_result) do
    FactoryBot.create(:rule_result, rule: profile.rules.sample, test_result: test_result, host: host)
  end

  before do
    logger = double(Rails.logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
    allow(Sidekiq).to receive(:logger).and_return(logger)
  end

  after do
    DeleteHost.clear
  end

  it 'performs and logs deletion' do
    expect(profile.hosts.count).not_to eql(0)
    expect(profile.score).not_to eql(0.0)

    DeleteHost.perform_async(message)

    expect(profile.test_results.count).to eql(1)
    expect(profile.rule_results.count).to eql(1)

    expect(Rails.logger).to receive(:audit_success).with("Deleted related records for host #{message_id}")
    DeleteHost.drain

    expect(profile.test_results.count).to eql(0)
    expect(profile.rule_results.count).to eql(0)
    expect(profile.hosts.count).to eql(0)
    expect(profile.reload.score).to eql(0.0)
  end

  context 'when multiple hosts exist under a profile' do
    let(:message_id) { profile.hosts.first.id }

    it 'deletes host and updates score and counters' do
      test_result.destroy
      rule_result.destroy

      FactoryBot.create_list(:host, 3, org_id: user.account.org_id) do |host|
        test_result = FactoryBot.create(:test_result, profile: profile, host: host)
        FactoryBot.create(:rule_result, rule: profile.rules.sample, test_result: test_result, host: host)
      end

      expect(profile.score).not_to eql(0.0)
      expect(profile.policy.test_result_host_count).to eql(3)

      old_score = profile.score
      DeleteHost.perform_async(message)
      DeleteHost.drain

      expect(profile.reload.score).not_to eql(old_score)
      expect(profile.policy.test_result_host_count).to eql(2)
    end
  end

  context 'when host to be deleted does not exist' do
    let(:message_id) { 'invalid-id' }

    it 'fails silently' do
      expect(profile.hosts.count).to eql(1)
      expect(profile.score).not_to eql(0.0)

      DeleteHost.perform_async(message)
      DeleteHost.drain

      expect(profile.hosts.count).to eql(1)
      expect(profile.reload.score).not_to eql(0.0)
    end
  end

  context 'when deletion is not possible' do
    let(:err_message) { "Failed to delete related records for host #{message_id}: StandardError" }

    before do
      DeleteHost.perform_async(message)
      expect_any_instance_of(DeleteHost).to receive(:remove_related).and_raise(StandardError)
    end

    it 'logs failure and raises an error' do
      expect(Rails.logger).to receive(:audit_fail).with(err_message)
      expect { DeleteHost.drain }.to raise_error(StandardError)
    end
  end
end
