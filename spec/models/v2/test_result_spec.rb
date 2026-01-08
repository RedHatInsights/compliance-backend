# frozen_string_literal: true

require 'rails_helper'

describe V2::TestResult do
  describe '.os_versions' do
    let(:versions) { ['7.1', '7.2', '7.3'] }

    let(:account) { FactoryBot.create(:account) }

    let(:policy) do
      FactoryBot.create(:v2_policy, os_major_version: 7, supports_minors: [1, 2, 3], account: account)
    end

    before do
      versions.each do |version|
        major, minor = version.split('.')
        FactoryBot.create_list(
          :system, (1..10).to_a.sample,
          os_major_version: major.to_i,
          os_minor_version: minor.to_i,
          policy_id: policy.id,
          account: account
        ).each do |sys|
          FactoryBot.create(:v2_test_result, system: sys, policy_id: policy.id)
        end
      end
    end

    subject { described_class.where.associated(:system) }

    it 'returns a unique and sorted set of all versions' do
      expect(subject.os_versions.to_set { |version| version.delete('"') }).to eq(versions.to_set)
    end
  end
  
  describe '#compliant' do
    let(:account) { FactoryBot.create(:v2_account) }
    let(:policy) do
      FactoryBot.create(:v2_policy, :for_tailoring, account: account, 
                        compliance_threshold: threshold,
                        os_major_version: 7,
                        supports_minors: [0])
    end

    context 'score == threshold' do
      let(:threshold) { 90.0 }

      it 'returns true when score equals threshold' do
        test_result = FactoryBot.create(:v2_test_result, policy_id: policy.id,
                                        account: account, score: 90.0, supported: true)
        allow(test_result).to receive(:report).and_return(policy)
        expect(test_result.compliant).to eq(true)
      end
    end

    context 'score comparison' do
      let(:threshold) { 90.0 }

      it 'returns true when score > threshold' do
        test_result = FactoryBot.create(:v2_test_result, policy_id: policy.id,
                                        account: account, score: 90.01, supported: true)
        allow(test_result).to receive(:report).and_return(policy)
        expect(test_result.compliant).to eq(true)
      end

      it 'returns false when score < threshold' do
        test_result = FactoryBot.create(:v2_test_result, policy_id: policy.id,
                                        account: account, score: 89.99, supported: true)
        allow(test_result).to receive(:report).and_return(policy)
        expect(test_result.compliant).to eq(false)
      end
    end

    context 'threshold changes' do
      let(:threshold) { 95.0 }

      it 'threshold change updates compliant status' do
        test_result = FactoryBot.create(:v2_test_result, policy_id: policy.id,
                                        account: account, score: 90.0, supported: true)
        allow(test_result).to receive(:report).and_return(policy)
        expect(test_result.compliant).to eq(false)

        policy.update!(compliance_threshold: 85.0)
        test_result.reload
        expect(test_result.compliant).to eq(true)
      end
    end

    context 'nil score' do
      let(:threshold) { 90.0 }

      it 'returns false when score is nil' do
        test_result = FactoryBot.create(:v2_test_result, policy_id: policy.id,
                                        account: account, score: nil, supported: false)
        allow(test_result).to receive(:report).and_return(policy)
        expect(test_result.compliant).to eq(false)
      end
    end
  end
end
