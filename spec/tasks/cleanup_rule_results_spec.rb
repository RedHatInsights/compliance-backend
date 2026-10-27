# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'rule_results:cleanup task' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  ENV_KEYS = %w[RULE_RESULTS_CLEANUP_ENABLED SUBTASKS BATCH_SIZE].freeze

  around do |example|
    original_envs = ENV_KEYS.to_h { |key| [key, ENV.fetch(key, nil)] }
    begin
      example.run
    ensure
      ENV_KEYS.each do |key|
        if original_envs[key].nil?
          ENV.delete(key)
        else
          ENV[key] = original_envs[key]
        end
      end
    end
  end

  before do
    Rake::Task['rule_results:cleanup'].reenable
  end

  let(:user) { FactoryBot.create(:user) }
  let(:policy) { FactoryBot.create(:policy, account: user.account, supports_minors: [0]) }
  let!(:tailoring) { FactoryBot.create(:tailoring, policy: policy, os_minor_version: 0) }
  let(:system) { FactoryBot.create(:system, account: user.account, os_minor_version: 0) }

  let!(:latest_test_result) { create_test_result(end_time: 10.minutes.ago) }
  let!(:latest_rule_result) { FactoryBot.create(:rule_result, test_result: latest_test_result) }
  let!(:older_test_result) { create_test_result(end_time: 1.hour.ago) }
  let!(:older_rule_result) { FactoryBot.create(:rule_result, test_result: older_test_result) }

  def create_test_result(end_time:)
    FactoryBot.create(
      :test_result,
      system: system,
      tailoring: tailoring,
      report_id: policy.id,
      start_time: end_time ? end_time - 5.minutes : 2.hours.ago,
      end_time: end_time
    )
  end

  # rubocop:disable Metrics/MethodLength
  def insert_orphan_rule_result(rule_id:, result:)
    orphan_id = Faker::Internet.uuid
    orphan_parent_id = Faker::Internet.uuid
    now = Time.current
    attributes = [
      {
        id: orphan_id,
        test_result_id: orphan_parent_id,
        rule_id: rule_id,
        result: result,
        created_at: now,
        updated_at: now
      }
    ]

    # The missing parent is intentional; bypass model validations for this fixture.
    # rubocop:disable Rails/SkipsModelValidations
    RuleResult.insert_all!(attributes)
    # rubocop:enable Rails/SkipsModelValidations

    [orphan_id, orphan_parent_id]
  end
  # rubocop:enable Metrics/MethodLength

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def run_cleanup(subtasks: nil, batch_size: nil)
    ENV['RULE_RESULTS_CLEANUP_ENABLED'] = 'true'
    ENV['SUBTASKS'] = subtasks unless subtasks.nil?
    ENV['BATCH_SIZE'] = batch_size.to_s unless batch_size.nil?
    capture_stdout { Rake::Task['rule_results:cleanup'].invoke }
  end

  it 'does nothing when the emergency stop is active' do
    ENV['RULE_RESULTS_CLEANUP_ENABLED'] = 'false'

    output = capture_stdout { Rake::Task['rule_results:cleanup'].invoke }

    expect(output).to include('rule_results:cleanup is disabled')
    expect(HistoricalTestResult.exists?(older_test_result.id)).to be(true)
    expect(RuleResult.exists?(older_rule_result.id)).to be(true)
  end

  it 'deletes an older historical result and its rule results' do
    run_cleanup(subtasks: 'older')

    expect(HistoricalTestResult.exists?(older_test_result.id)).to be(false)
    expect(RuleResult.exists?(older_rule_result.id)).to be(false)
  end

  it 'keeps the historical result with the greatest end_time and its rule results' do
    run_cleanup(subtasks: 'older')

    expect(HistoricalTestResult.exists?(latest_test_result.id)).to be(true)
    expect(RuleResult.exists?(latest_rule_result.id)).to be(true)
  end

  it 'deletes historical results with a NULL end_time and their rule results' do
    null_result = create_test_result(end_time: nil)
    null_rule_result = FactoryBot.create(:rule_result, test_result: null_result)

    run_cleanup(subtasks: 'older')

    expect(HistoricalTestResult.exists?(null_result.id)).to be(false)
    expect(RuleResult.exists?(null_rule_result.id)).to be(false)
  end

  it 'deletes one older result per run when BATCH_SIZE=1 and leaves the latest' do
    additional_older_result = create_test_result(end_time: 2.hours.ago)
    additional_older_rule_result = FactoryBot.create(:rule_result, test_result: additional_older_result)

    output = run_cleanup(subtasks: 'older', batch_size: 1)

    expect(output.scan('Older batch').size).to eq(1)
    remaining_older_parents = [older_test_result, additional_older_result].select do |result|
      HistoricalTestResult.exists?(result.id)
    end
    remaining_older_rules = [older_rule_result, additional_older_rule_result].select do |result|
      RuleResult.exists?(result.id)
    end
    expect(remaining_older_parents.size).to eq(1)
    expect(remaining_older_rules.size).to eq(1)
    expect(remaining_older_rules.first.test_result_id).to eq(remaining_older_parents.first.id)
    expect(HistoricalTestResult.exists?(latest_test_result.id)).to be(true)
    expect(RuleResult.exists?(latest_rule_result.id)).to be(true)
  end

  it 'deletes one orphan per run when BATCH_SIZE=1 and leaves the other' do
    first_orphan_id, = insert_orphan_rule_result(
      rule_id: latest_rule_result.rule_id,
      result: latest_rule_result.result
    )
    second_orphan_id, = insert_orphan_rule_result(
      rule_id: older_rule_result.rule_id,
      result: older_rule_result.result
    )

    output = run_cleanup(subtasks: 'orphans', batch_size: 1)

    remaining_orphans = [first_orphan_id, second_orphan_id].select { |id| RuleResult.exists?(id) }
    expect(output.scan('Orphans batch').size).to eq(1)
    expect(remaining_orphans.size).to eq(1)
    expect(RuleResult.exists?(latest_rule_result.id)).to be(true)
    expect(RuleResult.exists?(older_rule_result.id)).to be(true)
  end

  it 'deletes orphan rule results and keeps rows whose parent exists' do
    orphan_id, orphan_parent_id = insert_orphan_rule_result(
      rule_id: latest_rule_result.rule_id,
      result: latest_rule_result.result
    )

    run_cleanup(subtasks: 'orphans')

    expect(RuleResult.exists?(orphan_id)).to be(false)
    expect(RuleResult.where(test_result_id: orphan_parent_id)).to be_empty
    expect(RuleResult.exists?(latest_rule_result.id)).to be(true)
    expect(HistoricalTestResult.exists?(older_test_result.id)).to be(true)
    expect(RuleResult.exists?(older_rule_result.id)).to be(true)
  end

  it 'defaults to older mode and leaves orphan rule results untouched' do
    orphan_id, = insert_orphan_rule_result(
      rule_id: latest_rule_result.rule_id,
      result: latest_rule_result.result
    )
    ENV.delete('SUBTASKS')

    output = run_cleanup

    expect(output).to include("Running mode 'older'")
    expect(output).not_to include("Running mode 'orphans'")
    expect(HistoricalTestResult.exists?(older_test_result.id)).to be(false)
    expect(RuleResult.exists?(older_rule_result.id)).to be(false)
    expect(RuleResult.exists?(orphan_id)).to be(true)
    expect(HistoricalTestResult.exists?(latest_test_result.id)).to be(true)
    expect(RuleResult.exists?(latest_rule_result.id)).to be(true)
  end

  it 'runs both selected modes in older-first order' do
    orphan_id, = insert_orphan_rule_result(
      rule_id: latest_rule_result.rule_id,
      result: latest_rule_result.result
    )

    output = run_cleanup(subtasks: 'orphans,older')

    expect(output.index("Running mode 'older'")).to be < output.index("Running mode 'orphans'")
    expect(HistoricalTestResult.exists?(older_test_result.id)).to be(false)
    expect(RuleResult.exists?(older_rule_result.id)).to be(false)
    expect(RuleResult.exists?(orphan_id)).to be(false)
    expect(HistoricalTestResult.exists?(latest_test_result.id)).to be(true)
    expect(RuleResult.exists?(latest_rule_result.id)).to be(true)
  end

  it 'deletes nothing on a second run' do
    run_cleanup
    Rake::Task['rule_results:cleanup'].reenable

    output = run_cleanup

    expect(output).to include('Deleted 0 rule_results and 0 historical_test_results')
    expect(HistoricalTestResult.exists?(latest_test_result.id)).to be(true)
    expect(RuleResult.exists?(latest_rule_result.id)).to be(true)
  end

  it 'logs unsupported modes and skips them without deleting rows' do
    output = run_cleanup(subtasks: 'unsupported')

    expect(output).to include('Unsupported modes provided: unsupported')
    expect(HistoricalTestResult.exists?(older_test_result.id)).to be(true)
    expect(RuleResult.exists?(older_rule_result.id)).to be(true)
  end

  it 'rejects zero and negative batch sizes' do
    %w[0 -1].each do |batch_size|
      Rake::Task['rule_results:cleanup'].reenable
      ENV['RULE_RESULTS_CLEANUP_ENABLED'] = 'true'
      ENV['BATCH_SIZE'] = batch_size

      expect do
        capture_stdout { Rake::Task['rule_results:cleanup'].invoke }
      end.to raise_error(ArgumentError, 'BATCH_SIZE must be positive')
    end
  end
end
