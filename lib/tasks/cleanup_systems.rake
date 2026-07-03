# frozen_string_literal: true

# Service class for cleaning up stale, deleted, and ineligible systems
# rubocop:disable Metrics/ClassLength
class SystemsCleaner
  DEFAULT_DELETED_RETENTION_DAYS = 14
  DEFAULT_STALE_RETENTION_DAYS = 30

  def initialize(batch_size:, logger:)
    @batch_size = batch_size
    @logger = logger
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def run(subtasks)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    if subtasks.include?('deleted')
      @logger.info("Running subtask 'deleted'...")
      cleanup_deleted_systems
    end

    if subtasks.include?('stale')
      @logger.info("Running subtask 'stale'...")
      cleanup_stale_systems
    end

    if subtasks.include?('filter')
      @logger.info("Running subtask 'filter'...")
      cleanup_filtered_systems
    end

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)
    @logger.info("systems:cleanup completed in #{elapsed}s.")
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  # Subtask: Deleted (Tombstones)
  # Hard-deletes systems soft-deleted (deleted_at IS NOT NULL) older than retention days in batches.
  # rubocop:disable Metrics/MethodLength
  def cleanup_deleted_systems
    retention_days = positive_integer_env('DELETED_RETENTION_DAYS', DEFAULT_DELETED_RETENTION_DAYS)
    cutoff_time = retention_days.days.ago

    sql = ActiveRecord::Base.sanitize_sql_array(
      [
        'SELECT id FROM systems WHERE deleted_at IS NOT NULL AND deleted_at < ?',
        cutoff_time
      ]
    )

    total = 0
    each_id_batch(sql) do |batch_ids|
      total += delete_systems_in_batches(batch_ids, 'deleted', cutoff_time: cutoff_time)
    end
    @logger.info("Completed subtask 'deleted'. Total systems cleaned up: #{total}")
  end
  # rubocop:enable Metrics/MethodLength

  # Subtask: Stale
  # Clean up stale systems based on stale_timestamp threshold if enabled in batches.
  # rubocop:disable Metrics/MethodLength
  def cleanup_stale_systems
    unless ENV['STALE_CLEANUP_ENABLED'] == 'true'
      @logger.info("Subtask 'stale': STALE_CLEANUP_ENABLED is not set to 'true'. Skipping stale systems cleanup.")
      return
    end

    retention_days = positive_integer_env('STALE_RETENTION_DAYS', DEFAULT_STALE_RETENTION_DAYS)
    cutoff_time = retention_days.days.ago

    sql = ActiveRecord::Base.sanitize_sql_array(
      [
        'SELECT id FROM systems WHERE deleted_at IS NULL AND stale_timestamp < ?',
        cutoff_time
      ]
    )

    total = 0
    each_id_batch(sql) do |batch_ids|
      total += delete_systems_in_batches(batch_ids, 'stale', cutoff_time: cutoff_time)
    end
    @logger.info("Completed subtask 'stale'. Total systems cleaned up: #{total}")
  end
  # rubocop:enable Metrics/MethodLength

  # Subtask: Filter (Kafka Filter requirements)
  # Deletes systems that should not have been imported in the first place in batches.
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def cleanup_filtered_systems
    total = 0

    # Select 1: Invalid or missing Insights ID
    sql_insights_id = <<~SQL
      SELECT id FROM systems
      WHERE deleted_at IS NULL
        AND (insights_id IS NULL OR insights_id = '00000000-0000-0000-0000-000000000000')
    SQL
    each_id_batch(sql_insights_id) do |batch_ids|
      total += delete_systems_in_batches(batch_ids, 'filter:insights_id')
    end

    # Select 2: Operating System is CentOS
    sql_centos = <<~SQL
      SELECT id FROM systems
      WHERE deleted_at IS NULL
        AND system_profile -> 'operating_system' ->> 'name' ILIKE '%centos%'
    SQL
    each_id_batch(sql_centos) do |batch_ids|
      total += delete_systems_in_batches(batch_ids, 'filter:centos')
    end

    # Select 3: Host type is 'edge' (retrieved from inventory.hosts)
    sql_edge = <<~SQL
      SELECT s.id FROM systems s
      INNER JOIN inventory.hosts h ON s.id = h.id
      WHERE s.deleted_at IS NULL
        AND h.system_profile ->> 'host_type' = 'edge'
    SQL
    each_id_batch(sql_edge, id_column: 's.id') do |batch_ids|
      total += delete_systems_in_batches(batch_ids, 'filter:edge')
    end

    # Select 4: BootC system with booted image digest present (retrieved from inventory.hosts)
    sql_bootc = <<~SQL
      SELECT s.id FROM systems s
      INNER JOIN inventory.hosts h ON s.id = h.id
      WHERE s.deleted_at IS NULL
        AND h.system_profile -> 'bootc_status' -> 'booted' ->> 'image_digest' IS NOT NULL
    SQL
    each_id_batch(sql_bootc, id_column: 's.id') do |batch_ids|
      total += delete_systems_in_batches(batch_ids, 'filter:bootc')
    end

    @logger.info("Completed subtask 'filter'. Total systems cleaned up: #{total}")
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Keyset-paginates SQL queries and yields batch IDs to prevent out-of-memory errors
  # rubocop:disable Metrics/MethodLength
  def each_id_batch(sql_query, id_column: 'id')
    last_id = nil
    loop do
      paged_sql = if last_id
                    if sql_query.match?(/where/i)
                      sql_query.sub(/where/i, "WHERE #{id_column} > '#{last_id}' AND")
                    else
                      "#{sql_query} WHERE #{id_column} > '#{last_id}'"
                    end
                  else
                    sql_query
                  end

      paged_sql += " ORDER BY #{id_column} LIMIT #{@batch_size}"

      batch_ids = ActiveRecord::Base.connection.select_values(paged_sql)
      break if batch_ids.empty?

      yield batch_ids

      last_id = batch_ids.last
      break if batch_ids.size < @batch_size
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Batch deletion of identified systems and their related records
  # rubocop:disable Metrics/AbcSize, Metrics/BlockLength
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def delete_systems_in_batches(batch_ids, subtask_name, cutoff_time: nil)
    ActiveRecord::Base.transaction do
      # Re-select and lock candidates in transaction to avoid TOCTOU race conditions (e.g. resurrection)
      query = KafkaSystem.unscoped.where(id: batch_ids).lock('FOR UPDATE OF systems')

      query = case subtask_name
              when 'deleted'
                query.where.not(deleted_at: nil).where(deleted_at: ...cutoff_time)
              when 'stale'
                query.where(stale_timestamp: ...cutoff_time)
              when 'filter:insights_id'
                query.where("insights_id IS NULL OR insights_id = '00000000-0000-0000-0000-000000000000'")
              when 'filter:centos'
                query.where("system_profile -> 'operating_system' ->> 'name' ILIKE '%centos%'")
              when 'filter:edge'
                query.joins('INNER JOIN inventory.hosts h ON systems.id = h.id')
                     .where("h.system_profile ->> 'host_type' = 'edge'")
              when 'filter:bootc'
                query.joins('INNER JOIN inventory.hosts h ON systems.id = h.id')
                     .where("h.system_profile -> 'bootc_status' -> 'booted' ->> 'image_digest' IS NOT NULL")
              else
                query
              end

      eligible_ids = query.pluck(:id)
      return 0 if eligible_ids.empty?

      # Purge related records
      results_count = HistoricalTestResult.where(system_id: eligible_ids).delete_all
      policy_systems_count = PolicySystem.where(system_id: eligible_ids).delete_all

      # Purge the systems (bypassing default_scope deleted_at: nil)
      systems_count = KafkaSystem.unscoped.where(id: eligible_ids).delete_all

      @logger.info("Deleted batch for #{subtask_name}: #{systems_count} systems, #{results_count} test results, " \
                   "#{policy_systems_count} policy-system associations.")
      systems_count
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/BlockLength
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  def positive_integer_env(name, default)
    value = Integer(ENV.fetch(name, default.to_s), 10)
    raise ArgumentError, "#{name} must be positive" unless value.positive?

    value
  rescue ArgumentError
    raise ArgumentError, "#{name} must be a positive integer"
  end
end
# rubocop:enable Metrics/ClassLength

namespace :systems do
  desc 'Cleanup stale, soft-deleted, and ineligible systems'
  task cleanup: :environment do
    subtasks = ENV.fetch('SUBTASKS', 'deleted,stale,filter').split(',')
    batch_size = Integer(ENV.fetch('BATCH_SIZE', '1000'), 10)
    raise ArgumentError, 'BATCH_SIZE must be positive' unless batch_size.positive?

    logger = Logger.new($stdout)
    logger.info("systems:cleanup started. Subtasks: #{subtasks.join(', ')} | BATCH_SIZE: #{batch_size}")

    SystemsCleaner.new(batch_size: batch_size, logger: logger).run(subtasks)
  end
end
