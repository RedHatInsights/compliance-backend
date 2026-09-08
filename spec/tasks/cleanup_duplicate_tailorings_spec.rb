# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'tailorings:cleanup_duplicates task' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  around do |example|
    original_confirm = ENV.fetch('CONFIRM', nil)
    begin
      example.run
    ensure
      if original_confirm.nil?
        ENV.delete('CONFIRM')
      else
        ENV['CONFIRM'] = original_confirm
      end
    end
  end

  before do
    # Re-enable the task before each test to allow multiple executions
    Rake::Task['tailorings:cleanup_duplicates'].reenable
    ENV.delete('CONFIRM')
  end

  let(:policy) { create(:policy, :for_tailoring, supports_minors: [0], system_count: 1) }
  let(:good_tailoring) { policy.tailorings.find_by(os_minor_version: 0) }

  # Builds a Tailoring bypassing app validations, mirroring how the legacy bugs produced
  # invalid rows directly at the DB level (no unique index existed to prevent them).
  # The unique index is dropped inside the example transaction so duplicates can be seeded;
  # transactional fixtures roll that DROP back after the example.
  # rubocop:disable Rails/SkipsModelValidations
  def build_invalid_tailoring(os_minor_version:, created_at: Time.zone.now)
    ActiveRecord::Base.connection.execute(
      'DROP INDEX IF EXISTS index_tailorings_on_policy_id_and_os_minor_version'
    )
    tailoring = policy.tailorings.build(
      profile: policy.profile, os_minor_version: os_minor_version, value_overrides: {}
    )
    tailoring.save!(validate: false)
    tailoring.update_column(:created_at, created_at)
    tailoring
  end
  # rubocop:enable Rails/SkipsModelValidations

  context 'when nothing needs cleaning' do
    it 'reports nothing to clean up and changes nothing' do
      good_tailoring
      output = nil

      expect do
        output = capture_stdout { Rake::Task['tailorings:cleanup_duplicates'].invoke }
      end.not_to(change(Tailoring, :count))

      expect(output).to include('nothing to clean up')
      expect(Tailoring.exists?(good_tailoring.id)).to be true
    end
  end

  context 'in dry-run mode (default, no CONFIRM)' do
    it 'reports the plan but deletes nothing' do
      good_tailoring
      null_tailoring = build_invalid_tailoring(os_minor_version: nil)
      output = nil

      expect do
        output = capture_stdout { Rake::Task['tailorings:cleanup_duplicates'].invoke }
      end.not_to(change(Tailoring, :count))

      expect(Tailoring.exists?(null_tailoring.id)).to be true
      expect(output).to include('1 tailorings to remove')
      expect(output).to include('dry run only, no data was changed')
    end

    it 'also does not delete when CONFIRM is set to anything other than true' do
      null_tailoring = build_invalid_tailoring(os_minor_version: nil)
      ENV['CONFIRM'] = 'false'

      expect do
        capture_stdout { Rake::Task['tailorings:cleanup_duplicates'].invoke }
      end.not_to(change(Tailoring, :count))

      expect(Tailoring.exists?(null_tailoring.id)).to be true
    end
  end

  context 'when CONFIRM=true' do
    it 'deletes NULL and race-condition duplicate tailorings, keeping legitimate ones' do
      good_tailoring
      null_tailoring = build_invalid_tailoring(os_minor_version: nil)
      keeper = build_invalid_tailoring(os_minor_version: 5, created_at: 2.days.ago)
      excess = build_invalid_tailoring(os_minor_version: 5, created_at: 1.hour.ago)
      ENV['CONFIRM'] = 'true'
      output = nil

      expect do
        output = capture_stdout { Rake::Task['tailorings:cleanup_duplicates'].invoke }
      end.to change(Tailoring, :count).by(-2)

      expect(Tailoring.exists?(good_tailoring.id)).to be true
      expect(Tailoring.exists?(keeper.id)).to be true
      expect(Tailoring.exists?(null_tailoring.id)).to be false
      expect(Tailoring.exists?(excess.id)).to be false
      expect(output).to include('Deleted 2 tailorings')
    end
  end
end
