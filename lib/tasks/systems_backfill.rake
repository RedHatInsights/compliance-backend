# frozen_string_literal: true

# rubocop:disable Style/Documentation
class SystemsBackfiller
  # rubocop:enable Style/Documentation
  def initialize(batch_size:, max_upserts:, logger:)
    @batch_size = batch_size
    @max_upserts = max_upserts
    @logger = logger
    @total_upserted = 0
  end

  def run
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    org_ids = discover_orgs
    process_orgs(org_ids)

    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = (end_time - start_time).round(2)

    @logger.info("systems:backfill completed in #{elapsed}s. " \
                 "Total upserted: #{@total_upserted}.")
  end

  private

  def discover_orgs
    @logger.info('Discovering org_ids from inventory.hosts...')
    org_ids = ActiveRecord::Base.connection.select_values('SELECT DISTINCT org_id FROM inventory.hosts')
    @logger.info("Found #{org_ids.size} org_ids. Starting pagination loop.")
    org_ids
  end

  def process_orgs(org_ids)
    org_ids.lazy.take_while { @total_upserted < @max_upserts }.each do |org_id|
      process_single_org(org_id)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def process_single_org(org_id)
    org_upserted = 0
    safe_org_id = ActiveRecord::Base.connection.quote_string(org_id)
    upsert_count = -1

    while upsert_count != 0 && @total_upserted < @max_upserts
      result = ActiveRecord::Base.connection.execute(generate_upsert_sql(safe_org_id))
      upsert_count = result.cmd_tuples

      @total_upserted += upsert_count
      org_upserted += upsert_count

      if upsert_count.positive?
        @logger.info("Batch complete: org_id=#{org_id} upserted=#{upsert_count}")
      else
        @logger.info("No more rows to backfill for org_id=#{org_id}")
      end
    end

    @logger.info("Finished org_id=#{org_id}. Total upserted for org: #{org_upserted}")
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def generate_upsert_sql(safe_org_id)
    <<-SQL
      WITH batch AS (
        SELECT h.id, h.account, h.org_id, h.display_name, h.tags, h.updated,
               h.created, h.stale_timestamp,
               jsonb_strip_nulls(jsonb_build_object(
                 'operating_system', h.system_profile->'operating_system',
                 'owner_id', h.system_profile->'owner_id'
               )) AS system_profile,
               h.groups, h.insights_id
        FROM inventory.hosts h
        LEFT JOIN systems s ON h.id = s.id
        WHERE h.org_id = '#{safe_org_id}'
          AND (s.id IS NULL OR h.updated > s.updated)
        LIMIT #{@batch_size}
      )
      INSERT INTO systems (
        id, account, org_id, display_name, tags, updated,
        created, stale_timestamp, system_profile, groups,
        insights_id, deleted_at
      )
      SELECT
        id, account, org_id, display_name, tags, updated,
        created, stale_timestamp, system_profile, groups,
        insights_id, NULL
      FROM batch
      ON CONFLICT (id) DO UPDATE SET
        account = EXCLUDED.account,
        org_id = EXCLUDED.org_id,
        display_name = EXCLUDED.display_name,
        tags = EXCLUDED.tags,
        updated = EXCLUDED.updated,
        created = EXCLUDED.created,
        stale_timestamp = EXCLUDED.stale_timestamp,
        system_profile = EXCLUDED.system_profile,
        groups = EXCLUDED.groups,
        insights_id = EXCLUDED.insights_id,
        deleted_at = EXCLUDED.deleted_at
      WHERE (systems.deleted_at IS NULL AND systems.updated < EXCLUDED.updated)
         OR (systems.deleted_at IS NOT NULL AND systems.deleted_at < EXCLUDED.updated);
    SQL
  end
  # rubocop:enable Metrics/MethodLength
end

namespace :systems do
  desc 'Bulk backfill data from inventory.hosts to the new systems table'
  task backfill: :environment do
    batch_size = ENV.fetch('BATCH_SIZE', 1000).to_i
    max_upserts = ENV.fetch('MAX_ROWS_PER_RUN', 50_000).to_i

    logger = Logger.new($stdout)
    logger.info("systems:backfill started. BATCH_SIZE=#{batch_size} MAX_ROWS_PER_RUN=#{max_upserts}")

    SystemsBackfiller.new(batch_size: batch_size, max_upserts: max_upserts, logger: logger).run
  end
end
