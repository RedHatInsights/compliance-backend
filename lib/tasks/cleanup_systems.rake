# frozen_string_literal: true

# Service class for cleaning up stale, deleted, and ineligible systems
class SystemsCleaner
  def initialize(batch_size:, logger:)
    @batch_size = batch_size
    @logger = logger
  end

  def run(subtasks)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    if subtasks.include?('deleted')
      @logger.info("Running subtask 'deleted'...")
      deleted_ids = deleted_system_ids
      delete_systems_in_batches(deleted_ids, 'deleted') if deleted_ids.any?
    end

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)
    @logger.info("systems:cleanup completed in #{elapsed}s.")
  end

  private

  # Subtask: Deleted (Tombstones)
  # Hard-deletes systems soft-deleted (deleted_at IS NOT NULL) older than retention days.
  def deleted_system_ids
    retention_days = ENV.fetch('DELETED_RETENTION_DAYS', 14).to_i
    cutoff_time = retention_days.days.ago

    sql = <<~SQL
      SELECT id FROM systems
      WHERE deleted_at IS NOT NULL
        AND deleted_at < '#{cutoff_time.iso8601}'
    SQL
    ActiveRecord::Base.connection.select_values(sql)
  end

  # rubocop:disable Metrics/MethodLength
  # Batch deletion of identified systems and their related records
  def delete_systems_in_batches(system_ids, subtask_name)
    total = system_ids.size
    @logger.info("Found #{total} systems to clean up for subtask '#{subtask_name}'.")

    system_ids.each_slice(@batch_size) do |batch_ids|
      ActiveRecord::Base.transaction do
        # Purge related records
        results_count = V2::HistoricalTestResult.where(system_id: batch_ids).delete_all
        policy_systems_count = V2::PolicySystem.where(system_id: batch_ids).delete_all

        # Purge the systems (bypassing default_scope deleted_at: nil)
        systems_count = KafkaSystem.unscoped.where(id: batch_ids).delete_all

        @logger.info("Deleted batch: #{systems_count} systems, #{results_count} test results, " \
                     "#{policy_systems_count} policy-system associations.")
      end
    end
    @logger.info("Completed subtask '#{subtask_name}'. Total systems cleaned up: #{total}")
  end
  # rubocop:enable Metrics/MethodLength
end

namespace :systems do
  desc 'Cleanup stale, soft-deleted, and ineligible systems'
  task cleanup: :environment do
    subtasks = ENV.fetch('SUBTASKS', 'deleted').split(',')
    batch_size = ENV.fetch('BATCH_SIZE', 1000).to_i

    logger = Logger.new($stdout)
    logger.info("systems:cleanup started. Subtasks: #{subtasks.join(', ')} | BATCH_SIZE: #{batch_size}")

    SystemsCleaner.new(batch_size: batch_size, logger: logger).run(subtasks)
  end
end
