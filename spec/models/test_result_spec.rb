# frozen_string_literal: true

require 'rails_helper'

describe TestResult do
  describe '.os_versions' do
    let(:versions) { ['7.1', '7.2', '7.3'] }

    let(:account) { FactoryBot.create(:account) }

    let(:policy) do
      FactoryBot.create(:policy, os_major_version: 7, supports_minors: [1, 2, 3], account: account)
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
          FactoryBot.create(:test_result, system: sys, report_id: policy.id)
        end
      end
    end

    subject { described_class.where.associated(:system) }

    it 'returns a unique and sorted set of all versions' do
      expect(subject.os_versions.to_set { |version| version.delete('"') }).to eq(versions.to_set)
    end
  end

  describe 'OS version readers' do
    let(:account) { FactoryBot.create(:account) }
    let(:policy) do
      FactoryBot.create(:policy, :for_tailoring, account: account, os_major_version: 9, supports_minors: [4])
    end
    let(:system) do
      FactoryBot.create(
        :system,
        account: account,
        policy_id: policy.id,
        os_major_version: 9,
        os_minor_version: 4,
        system_profile: {
          'operating_system' => { 'major' => 8, 'minor' => 2 }
        }
      )
    end
    let(:test_result) { FactoryBot.create(:test_result, system: system, report_id: policy.id) }

    it 'uses native system versions when loaded through the association' do
      expect(test_result.os_major_version).to eq(9)
      expect(test_result.os_minor_version).to eq(4)
    end

    it 'uses selected native aliases, including selected NULL values' do
      selected = described_class.joins(:system).select(
        'test_results.*', 'systems.os_major_version AS system__os_major_version',
        'systems.os_minor_version AS system__os_minor_version'
      ).find(test_result.id)

      expect(selected.os_major_version).to eq(9)
      expect(selected.os_minor_version).to eq(4)

      selected = described_class.find_by_sql([<<~SQL, test_result.id]).first
        SELECT test_results.*, NULL AS system__os_major_version, NULL AS system__os_minor_version
        FROM test_results
        WHERE test_results.id = ?
      SQL
      expect(selected.os_major_version).to be_nil
      expect(selected.os_minor_version).to be_nil
    end
  end

  describe '#compliant' do
    let(:account) { FactoryBot.create(:account) }
    let(:policy) do
      FactoryBot.create(
        :policy,
        :for_tailoring,
        account: account,
        compliance_threshold: threshold,
        os_major_version: 7,
        supports_minors: [0]
      )
    end
    let(:test_result) do
      FactoryBot.create(
        :test_result,
        report_id: policy.id,
        account: account,
        score: score
      )
    end

    context 'score comparison' do
      let(:threshold) { 90.0 }

      context 'when score > threshold' do
        let(:score) { 90.01 }

        it 'reports compliant' do
          expect(test_result.compliant).to eq(true)
        end
      end

      context 'when score == threshold' do
        let(:score) { 90.0 }

        it 'reports compliant' do
          expect(test_result.compliant).to eq(true)
        end
      end

      context 'score == threshold' do
        let(:score) { 90.0 }

        it 'returns true when score equals threshold' do
          expect(test_result.compliant).to eq(true)
        end
      end

      context 'when score < threshold' do
        let(:score) { 89.99 }

        it 'reports non-compliant' do
          allow(test_result).to receive(:report).and_return(policy)
          expect(test_result.compliant).to eq(false)
        end
      end
    end

    context 'threshold changes' do
      let(:threshold) { 95.0 }
      let(:score) { 90.0 }

      it 'threshold change updates compliant status' do
        allow(test_result).to receive(:report).and_return(policy)
        expect(test_result.compliant).to eq(false)

        policy.update!(compliance_threshold: 85.0)
        test_result.reload
        expect(test_result.compliant).to eq(true)
      end
    end

    context 'nil score' do
      let(:threshold) { 90.0 }
      let(:score) { nil }

      it 'returns false when score is nil' do
        expect(test_result.compliant).to eq(false)
      end
    end
  end
end
