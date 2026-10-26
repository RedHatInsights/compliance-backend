# frozen_string_literal: true

# Removes stale historical test results and orphaned rule results in batches.
# rubocop:disable Metrics/ClassLength
class RuleResultsCleaner
  SUPPORTED_MODES = %w[older orphans].freeze

  def initialize(batch_size:, logger:)
    raise ArgumentError, 'BATCH_SIZE must be positive' unless batch_size.positive?

    @batch_size = batch_size
    @logger = logger
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def run(modes)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    unsupported = modes.uniq - SUPPORTED_MODES
    if unsupported.any?
      @logger.warn("Unsupported modes provided: #{unsupported.join(', ')}. Supported modes are: " \
                   "#{SUPPORTED_MODES.join(', ')}.")
    end

    rule_results_count = 0
    historical_test_results_count = 0

    SUPPORTED_MODES.each do |mode|
      next unless modes.include?(mode)

      @logger.info("Running mode '#{mode}' with BATCH_SIZE: #{@batch_size}.")
      if mode == 'older'
        rule_results_deleted, historical_test_results_deleted = cleanup_older
        rule_results_count += rule_results_deleted
        historical_test_results_count += historical_test_results_deleted
      else
        rule_results_count += cleanup_orphans
      end
    end

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)
    @logger.info("rule_results:cleanup completed in #{elapsed}s. Deleted #{rule_results_count} rule_results " \
                 "and #{historical_test_results_count} historical_test_results.")
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  # Parent rows define each batch; child rows and eligible parents are deleted
  # before the transaction commits. Locked children keep their parent for a later run.
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def cleanup_older
    total_rule_results = 0
    total_historical_test_results = 0
    last_id = nil
    batch_number = 0

    loop do
      parent_ids, rule_results_deleted, historical_test_results_deleted = ActiveRecord::Base.transaction do
        ids = stale_historical_test_result_ids(last_id)
        if ids.empty?
          [ids, 0, 0]
        else
          child_ids = RuleResult.where(test_result_id: ids).select(:id).lock('FOR UPDATE SKIP LOCKED')
          deleted_rule_results = RuleResult.where(id: child_ids).delete_all
          deleted_historical_test_results = delete_stale_parents_without_children(ids)
          [ids, deleted_rule_results, deleted_historical_test_results]
        end
      end
      break if parent_ids.empty?

      batch_number += 1
      last_id = parent_ids.last
      total_rule_results += rule_results_deleted
      total_historical_test_results += historical_test_results_deleted
      @logger.info("Older batch #{batch_number}: #{rule_results_deleted} rule_results, " \
                   "#{historical_test_results_deleted} historical_test_results deleted from " \
                   "#{parent_ids.size} locked parents.")
    end

    [total_rule_results, total_historical_test_results]
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def stale_historical_test_result_ids(last_id)
    cursor = "AND htr.id > #{ActiveRecord::Base.connection.quote(last_id)}" if last_id

    ActiveRecord::Base.connection.select_values(<<~SQL)
      SELECT htr.id
      FROM historical_test_results htr
      WHERE #{stale_test_result_condition('htr')}
        #{cursor}
      ORDER BY htr.id
      LIMIT #{@batch_size}
      FOR UPDATE OF htr SKIP LOCKED
    SQL
  end
  # rubocop:enable Metrics/MethodLength

  def delete_stale_parents_without_children(parent_ids)
    HistoricalTestResult.where(id: parent_ids)
                        .where(stale_test_result_condition('historical_test_results'))
                        .where(<<~SQL.squish)
                          NOT EXISTS (
                            SELECT 1
                            FROM rule_results
                            WHERE rule_results.test_result_id = historical_test_results.id
                          )
                        SQL
                        .delete_all
  end

  # rubocop:disable Metrics/MethodLength
  def stale_test_result_condition(table_alias)
    <<~SQL.squish
      (#{table_alias}.end_time IS NULL OR EXISTS (
        SELECT 1
        FROM historical_test_results newer
        WHERE newer.system_id = #{table_alias}.system_id
          AND newer.tailoring_id = #{table_alias}.tailoring_id
          AND newer.end_time > #{table_alias}.end_time
      ))
    SQL
  end
  # rubocop:enable Metrics/MethodLength

  # Rule-result rows are paginated independently because orphan parents no longer exist.
  # rubocop:disable Metrics/MethodLength
  def cleanup_orphans
    total = 0
    last_id = nil
    batch_number = 0

    loop do
      deleted_ids = ActiveRecord::Base.transaction do
        ids = orphan_rule_result_ids(last_id)
        RuleResult.where(id: ids).delete_all if ids.any?
        ids
      end
      break if deleted_ids.empty?

      batch_number += 1
      last_id = deleted_ids.last
      total += deleted_ids.size
      @logger.info("Orphans batch #{batch_number}: deleted #{deleted_ids.size} rule_results.")
    end

    total
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def orphan_rule_result_ids(last_id)
    cursor = "AND rr.id > #{ActiveRecord::Base.connection.quote(last_id)}" if last_id

    ActiveRecord::Base.connection.select_values(<<~SQL)
      SELECT rr.id
      FROM rule_results rr
      WHERE NOT EXISTS (
        SELECT 1
        FROM historical_test_results htr
        WHERE htr.id = rr.test_result_id
      )
        #{cursor}
      ORDER BY rr.id
      LIMIT #{@batch_size}
      FOR UPDATE OF rr SKIP LOCKED
    SQL
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength

namespace :rule_results do
  desc 'Remove stale and orphaned rule results and historical test results'
  task cleanup: :environment do
    logger = Logger.new($stdout)

    unless ENV['RULE_RESULTS_CLEANUP_ENABLED'] == 'true'
      logger.info('rule_results:cleanup is disabled. Set RULE_RESULTS_CLEANUP_ENABLED=true to run.')
      next
    end

    batch_size = Integer(ENV.fetch('BATCH_SIZE', '100'), 10)
    raise ArgumentError, 'BATCH_SIZE must be positive' unless batch_size.positive?

    modes = ENV.fetch('SUBTASKS', 'older').split(',').map(&:strip)
    logger.info("rule_results:cleanup started. Modes: #{modes.join(', ')} | BATCH_SIZE: #{batch_size}")
    RuleResultsCleaner.new(batch_size: batch_size, logger: logger).run(modes)
  end
end
