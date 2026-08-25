# frozen_string_literal: true

# Removes tailorings left over from two known data-integrity issues, along with every
# dependent record, using bulk SQL (never loading/destroying records one by one):
#
#   1. Tailorings created with a NULL `os_minor_version` (a side effect of V1 profile cloning).
#   2. Duplicate tailorings for the same `(policy_id, os_minor_version)` pair, created by
#      a `find_or_create_by!` race condition that a unique index will now prevent. For each
#      duplicate group the oldest tailoring is kept (it is the one most likely to carry
#      real scan history); the rest are considered excess.
#
# `plan` is read-only and safe to call at any time. `run!` is destructive: it deletes the
# same records `plan` reports, cascading through dependents in a single transaction so the
# database is never left in a half-cleaned state.
class DuplicateTailoringsCleaner
  # Selects the ids of every tailoring that should be removed. Standalone so it can be
  # embedded both in a read-only report query and in the temp table used by the delete.
  TARGET_TAILORING_IDS_SQL = <<~SQL
    SELECT id FROM tailorings WHERE os_minor_version IS NULL
    UNION
    SELECT id FROM (
      SELECT id, ROW_NUMBER() OVER (
        PARTITION BY policy_id, os_minor_version ORDER BY created_at ASC, id ASC
      ) AS rn
      FROM tailorings
      WHERE os_minor_version IS NOT NULL
    ) ranked
    WHERE rn > 1
  SQL

  PLAN_SQL = <<~SQL.freeze
    WITH targets AS (
      #{TARGET_TAILORING_IDS_SQL}
    ), target_test_results AS (
      SELECT id FROM historical_test_results WHERE tailoring_id IN (SELECT id FROM targets)
    )
    SELECT
      (SELECT count(*) FROM tailorings WHERE os_minor_version IS NULL) AS null_tailorings,
      (SELECT count(*) FROM targets) AS tailorings,
      (SELECT count(*) FROM tailoring_rules WHERE tailoring_id IN (SELECT id FROM targets)) AS tailoring_rules,
      (SELECT count(*) FROM target_test_results) AS test_results,
      (SELECT count(*) FROM rule_results WHERE test_result_id IN (SELECT id FROM target_test_results)) AS rule_results
  SQL

  COUNT_KEYS = %w[null_tailorings tailorings tailoring_rules test_results rule_results].freeze

  def initialize(logger: Rails.logger)
    @logger = logger
  end

  # Read-only. Returns a Hash of counts describing what `run!` would delete, and logs a
  # one-line summary. Never modifies the database.
  def plan
    row = connection.select_one(PLAN_SQL)
    counts = COUNT_KEYS.to_h { |key| [key, row.fetch(key).to_i] }
    @logger.info(summary(counts))
    counts
  end

  # Destructive. Deletes the target tailorings and every dependent record in a single
  # transaction: if any step fails, nothing is deleted. Returns the same shape as `plan`,
  # reflecting what was actually removed. Safe to call repeatedly (a second call with
  # nothing left to clean is a no-op).
  def run!
    counts = plan
    return counts if counts.fetch('tailorings').zero?

    delete_targets_and_dependents
    @logger.info('DuplicateTailoringsCleaner: cleanup committed successfully.')

    counts
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  def summary(counts)
    duplicates = counts.fetch('tailorings') - counts.fetch('null_tailorings')

    "DuplicateTailoringsCleaner: #{counts.fetch('tailorings')} tailorings to remove " \
    "(#{counts.fetch('null_tailorings')} with NULL os_minor_version, #{duplicates} race-condition duplicates), " \
    "cascading to #{counts.fetch('tailoring_rules')} tailoring_rules, " \
    "#{counts.fetch('test_results')} test_results, #{counts.fetch('rule_results')} rule_results."
  end

  def delete_targets_and_dependents
    connection.transaction do
      create_target_table
      delete_rule_results
      delete_test_results
      delete_tailoring_rules
      delete_tailorings
    end
  end

  # Snapshots the ids to delete once, up front, so every subsequent DELETE in this
  # transaction agrees on exactly the same set of tailorings, regardless of statement order.
  def create_target_table
    connection.execute(<<~SQL)
      CREATE TEMP TABLE tailorings_to_delete ON COMMIT DROP AS
      #{TARGET_TAILORING_IDS_SQL}
    SQL
  end

  def delete_rule_results
    deleted = connection.execute(<<~SQL).cmd_tuples
      DELETE FROM rule_results
      WHERE test_result_id IN (
        SELECT id FROM historical_test_results WHERE tailoring_id IN (SELECT id FROM tailorings_to_delete)
      )
    SQL
    @logger.info("DuplicateTailoringsCleaner: deleted #{deleted} rule_results.")
  end

  def delete_test_results
    deleted = connection.execute(<<~SQL).cmd_tuples
      DELETE FROM historical_test_results WHERE tailoring_id IN (SELECT id FROM tailorings_to_delete)
    SQL
    @logger.info("DuplicateTailoringsCleaner: deleted #{deleted} historical_test_results.")
  end

  def delete_tailoring_rules
    deleted = connection.execute(<<~SQL).cmd_tuples
      DELETE FROM tailoring_rules WHERE tailoring_id IN (SELECT id FROM tailorings_to_delete)
    SQL
    @logger.info("DuplicateTailoringsCleaner: deleted #{deleted} tailoring_rules.")
  end

  def delete_tailorings
    deleted = connection.execute(<<~SQL).cmd_tuples
      DELETE FROM tailorings WHERE id IN (SELECT id FROM tailorings_to_delete)
    SQL
    @logger.info("DuplicateTailoringsCleaner: deleted #{deleted} tailorings.")
  end
end
