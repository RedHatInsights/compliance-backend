# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Style/Documentation
class SystemsProfileFieldsBackfiller
  # rubocop:enable Style/Documentation
  NULL_TARGET_SQL = <<~SQL.squish.freeze
    owner_id IS NULL OR os_major_version IS NULL OR os_minor_version IS NULL
  SQL

  def initialize(batch_size:, max_updates:, logger:)
    @batch_size = batch_size
    @max_updates = max_updates
    @logger = logger
    @totals = Hash.new(0)
  end

  def run
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    log_start
    process_candidates
    log_completion(started)
    @totals[:successful_rows]
  end

  private

  def process_candidates
    cursor = nil
    loop do
      ids = candidate_ids(cursor)
      break if ids.empty?

      @totals[:selected_rows] += ids.size
      process_batch(ids)
      cursor = ids.last
      return if limit_reached?
    end
  end

  def candidate_ids(cursor)
    relation = System.unscoped
                     .where(deleted_at: nil)
                     .where(NULL_TARGET_SQL)
                     .order(:id)
                     .limit(@batch_size)
    relation = relation.where('id > ?', cursor) if cursor
    relation.pluck(:id)
  end

  def process_batch(ids)
    System.transaction do
      locked_candidates(ids).each do |system|
        process_locked_candidate(system)
        break if limit_reached?
      end
    end
  end

  def locked_candidates(ids)
    System.unscoped
          .where(id: ids, deleted_at: nil)
          .where(NULL_TARGET_SQL)
          .order(:id)
          .lock('FOR UPDATE OF systems')
  end

  def process_locked_candidate(system)
    @totals[:scanned_rows] += 1
    result = SystemProfileNativeFields.normalize(system.system_profile)
    updates = null_target_updates(system, result)
    serialized_updates, serialization_failed = serialize_updates(system, updates)
    persisted = persist_updates(system, serialized_updates)
    @totals[:failed_rows] += 1 if serialization_failed || persisted == :failed
    merge_outcome(candidate_outcome(system, result, persisted == :written))
  end

  # rubocop:disable Metrics/MethodLength
  def serialize_updates(system, updates)
    failed = false
    accepted = updates.each_with_object({}) do |(column, value), values|
      values[column] = System.type_for_attribute(column).serialize(value)
    rescue ActiveModel::RangeError => e
      failed = true
      @totals[:rejected_fields] += 1
      @logger.error(
        "systems:backfill_profile_fields rejected system_id=#{system.id} " \
        "column=#{column} error=#{e.class}"
      )
    end
    [accepted, failed]
  end
  # rubocop:enable Metrics/MethodLength

  def persist_updates(system, updates)
    return :none if updates.empty?

    System.transaction(requires_new: true) do
      system.update_columns(updates) # rubocop:disable Rails/SkipsModelValidations
    end
    :written
  rescue ActiveRecord::ActiveRecordError => e
    @logger.error("systems:backfill_profile_fields failed system_id=#{system.id} error=#{e.class}")
    :failed
  end

  def null_target_updates(system, result)
    result.native_attributes.select do |column, value|
      system[column].nil? && !value.nil?
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def candidate_outcome(system, result, updated)
    {
      successful_rows: updated ? 1 : 0,
      malformed_owner_ids: system[:owner_id].nil? && result.malformed_owner_id? ? 1 : 0,
      malformed_os_major: system[:os_major_version].nil? && result.malformed_os_major? ? 1 : 0,
      malformed_os_minor: system[:os_minor_version].nil? && result.malformed_os_minor? ? 1 : 0
    }
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def merge_outcome(outcome)
    outcome.each { |key, value| @totals[key] += value }
  end

  def limit_reached?
    @totals[:successful_rows] >= @max_updates
  end

  def log_start
    @logger.info(
      "systems:backfill_profile_fields BATCH_SIZE=#{@batch_size} " \
      "MAX_ROWS_PER_RUN=#{@max_updates}"
    )
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def log_completion(started)
    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)
    reason = if limit_reached?
               "Stopped after reaching MAX_ROWS_PER_RUN=#{@max_updates}"
             else
               "Reached the end of this invocation's keyset scan"
             end
    @logger.info(
      "#{reason}. selected_rows=#{@totals[:selected_rows]} " \
      "scanned_rows=#{@totals[:scanned_rows]} " \
      "successful_rows=#{@totals[:successful_rows]} in #{elapsed}s; " \
      "malformed_owner_ids=#{@totals[:malformed_owner_ids]} " \
      "malformed_os_major=#{@totals[:malformed_os_major]} " \
      "malformed_os_minor=#{@totals[:malformed_os_minor]} " \
      "rejected_fields=#{@totals[:rejected_fields]} " \
      "failed_rows=#{@totals[:failed_rows]}"
    )
    return unless @totals[:failed_rows].positive?

    @logger.warn(
      "systems:backfill_profile_fields completed with failed_rows=#{@totals[:failed_rows]}; " \
      'investigate persistence errors before Phase 5 cleanup'
    )
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength

namespace :systems do
  desc 'Backfill null native owner and OS columns from system_profile JSONB'
  task backfill_profile_fields: :environment do
    parse_positive = lambda do |name, default|
      value = Integer(ENV.fetch(name, default.to_s), 10)
      raise ArgumentError unless value.positive?

      value
    rescue ArgumentError
      raise ArgumentError, "#{name} must be a positive integer"
    end

    SystemsProfileFieldsBackfiller.new(
      batch_size: parse_positive.call('BATCH_SIZE', 1000),
      max_updates: parse_positive.call('MAX_ROWS_PER_RUN', 50_000),
      logger: Logger.new($stdout)
    ).run
  end
end
