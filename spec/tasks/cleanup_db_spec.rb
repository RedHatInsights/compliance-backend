# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'cleanup_db task' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  def suppress_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  describe 'cleanup_db' do
    it 'removes dangling records' do
      policy = create(:policy, supports_minors: [0], system_count: 1)
      tailoring = policy.tailorings.first
      rule = create(:rule, security_guide: policy.profile.security_guide)

      create(:account, org_id: '8675309')

      TestResult.new(
        system_id: SecureRandom.uuid,
        tailoring_id: tailoring.id,
        report_id: policy.id,
        score: 0,
        supported: true,
        start_time: Time.zone.now,
        end_time: Time.zone.now
      ).save(validate: false)

      RuleResult.new(
        test_result_id: SecureRandom.uuid,
        rule_id: rule.id,
        result: 'pass'
      ).save(validate: false)

      policy.systems.first.delete

      expect do
        suppress_stdout { Rake::Task['cleanup_db'].execute }
      end.to change(Account, :count).by(-1)
         .and change(TestResult, :count).by(-1)
         .and change(RuleResult, :count).by(-1)
         .and change(PolicySystem, :count).by(-1)
    end

    it 'does not remove accounts with a policy or a system' do
      create(:policy)
      create(:system)

      expect do
        suppress_stdout { Rake::Task['cleanup_db'].execute }
      end.not_to change(Account, :count)
    end
  end
end
