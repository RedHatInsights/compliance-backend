# frozen_string_literal: true

require 'rails_helper'

describe DuplicateTailoringsCleaner do
  let(:logger) { Logger.new(StringIO.new) }
  let(:cleaner) { described_class.new(logger: logger) }

  let(:policy) { create(:policy, :for_tailoring, supports_minors: [0], system_count: 1) }
  let(:good_tailoring) { policy.tailorings.find_by(os_minor_version: 0) }

  let(:empty_plan) do
    { 'null_tailorings' => 0, 'tailorings' => 0, 'tailoring_rules' => 0, 'test_results' => 0, 'rule_results' => 0 }
  end

  # Builds a Tailoring bypassing app validations, mirroring how the legacy bugs produced
  # invalid rows directly at the DB level (no unique index existed to prevent them).
  # rubocop:disable Rails/SkipsModelValidations
  def build_invalid_tailoring(os_minor_version:, created_at: Time.zone.now)
    tailoring = policy.tailorings.build(
      profile: policy.profile, os_minor_version: os_minor_version, value_overrides: {}
    )
    tailoring.save!(validate: false)
    tailoring.update_column(:created_at, created_at)
    tailoring
  end
  # rubocop:enable Rails/SkipsModelValidations

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def attach_test_result(tailoring)
    test_result = TestResult.new(
      system_id: SecureRandom.uuid,
      tailoring_id: tailoring.id,
      report_id: policy.id,
      score: 0,
      supported: true,
      start_time: 1.hour.ago,
      end_time: Time.zone.now
    )
    test_result.save!(validate: false)

    RuleResult.new(
      test_result_id: test_result.id,
      rule_id: policy.profile.rules.first.id,
      result: 'pass'
    ).save!(validate: false)

    test_result
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  describe '#plan' do
    it 'is read-only and reports nothing when there are no bad tailorings' do
      good_tailoring

      expect { cleaner.plan }.not_to change(Tailoring, :count)
      expect(cleaner.plan).to eq(empty_plan)
    end

    it 'counts NULL os_minor_version tailorings and their dependents' do
      good_tailoring
      null_tailoring = build_invalid_tailoring(os_minor_version: nil)
      attach_test_result(null_tailoring)

      plan = cleaner.plan

      expect(plan['null_tailorings']).to eq(1)
      expect(plan['tailorings']).to eq(1)
      expect(plan['test_results']).to eq(1)
      expect(plan['rule_results']).to eq(1)
      expect(plan['tailoring_rules']).to eq(null_tailoring.tailoring_rules.count)
    end

    it 'counts every duplicate but the oldest in a (policy_id, os_minor_version) group' do
      good_tailoring
      build_invalid_tailoring(os_minor_version: 5, created_at: 2.days.ago)
      excess1 = build_invalid_tailoring(os_minor_version: 5, created_at: 1.day.ago)
      excess2 = build_invalid_tailoring(os_minor_version: 5, created_at: 1.hour.ago)

      plan = cleaner.plan

      expect(plan['null_tailorings']).to eq(0)
      expect(plan['tailorings']).to eq(2)
      expect(plan['tailoring_rules']).to eq(excess1.tailoring_rules.count + excess2.tailoring_rules.count)
    end

    it 'never counts distinct, legitimate tailorings' do
      good_tailoring
      other_policy = create(:policy, :for_tailoring, supports_minors: [1], system_count: 1)
      other_tailoring = other_policy.tailorings.find_by(os_minor_version: 1)

      expect(cleaner.plan).to eq(empty_plan)
      expect(Tailoring.exists?(good_tailoring.id)).to be true
      expect(Tailoring.exists?(other_tailoring.id)).to be true
    end
  end

  describe '#run!' do
    it 'is a no-op when there is nothing to clean up' do
      good_tailoring

      expect { cleaner.run! }.not_to change(Tailoring, :count)
      expect(cleaner.run!).to eq(empty_plan)
    end

    it 'deletes NULL os_minor_version tailorings and cascades to every dependent record' do
      good_tailoring
      null_tailoring = build_invalid_tailoring(os_minor_version: nil)
      test_result = attach_test_result(null_tailoring)

      result = cleaner.run!

      expect(result['tailorings']).to eq(1)
      expect(Tailoring.exists?(null_tailoring.id)).to be false
      expect(HistoricalTestResult.exists?(test_result.id)).to be false
      expect(RuleResult.where(test_result_id: test_result.id)).to be_empty
      expect(TailoringRule.where(tailoring_id: null_tailoring.id)).to be_empty
      expect(Tailoring.exists?(good_tailoring.id)).to be true
    end

    it 'keeps the oldest tailoring in a duplicate group and deletes the rest' do
      good_tailoring
      keeper = build_invalid_tailoring(os_minor_version: 5, created_at: 2.days.ago)
      keeper_result = attach_test_result(keeper)
      excess1 = build_invalid_tailoring(os_minor_version: 5, created_at: 1.day.ago)
      excess2 = build_invalid_tailoring(os_minor_version: 5, created_at: 1.hour.ago)

      result = cleaner.run!

      expect(result['tailorings']).to eq(2)
      expect(Tailoring.exists?(keeper.id)).to be true
      expect(HistoricalTestResult.exists?(keeper_result.id)).to be true
      expect(Tailoring.exists?(excess1.id)).to be false
      expect(Tailoring.exists?(excess2.id)).to be false
      expect(Tailoring.exists?(good_tailoring.id)).to be true
    end

    it 'is idempotent: a second run finds nothing left to delete' do
      build_invalid_tailoring(os_minor_version: nil)

      cleaner.run!

      expect(cleaner.run!).to eq(empty_plan)
    end

    it 'rolls back every delete if any step in the transaction fails' do
      good_tailoring
      null_tailoring = build_invalid_tailoring(os_minor_version: nil)
      test_result = attach_test_result(null_tailoring)

      connection = ActiveRecord::Base.connection
      error_message = Faker::Lorem.sentence
      allow(connection).to receive(:execute).and_wrap_original do |original, sql, *args|
        # Let earlier steps run, then fail partway through to prove the whole
        # transaction is rolled back rather than leaving a half-cleaned database.
        raise ActiveRecord::StatementInvalid, error_message if sql.include?('DELETE FROM historical_test_results')

        original.call(sql, *args)
      end

      expect { cleaner.run! }.to raise_error(ActiveRecord::StatementInvalid, error_message)

      expect(Tailoring.exists?(null_tailoring.id)).to be true
      expect(HistoricalTestResult.exists?(test_result.id)).to be true
      expect(RuleResult.where(test_result_id: test_result.id)).not_to be_empty
      expect(Tailoring.exists?(good_tailoring.id)).to be true
    end
  end
end
