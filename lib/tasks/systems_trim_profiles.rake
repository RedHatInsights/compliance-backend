# frozen_string_literal: true

namespace :systems do
  desc 'Strip bloated system_profile JSONB down to operating_system + owner_id'
  task trim_profiles: :environment do
    batch_size = ENV.fetch('BATCH_SIZE', 1000).to_i
    max_updates = ENV.fetch('MAX_ROWS_PER_RUN', 100_000).to_i
    logger = Logger.new($stdout)
    total = 0

    logger.info("systems:trim_profiles BATCH_SIZE=#{batch_size} MAX_ROWS_PER_RUN=#{max_updates}")

    loop do
      updated = ActiveRecord::Base.connection.execute(<<-SQL).cmd_tuples
        UPDATE systems SET system_profile = jsonb_strip_nulls(jsonb_build_object(
          'operating_system', system_profile->'operating_system',
          'owner_id',         system_profile->'owner_id'
        ))
        WHERE id IN (
          SELECT id FROM systems
          WHERE system_profile ?| array['arch', 'installed_packages', 'cpu_flags']
          LIMIT #{batch_size}
        )
      SQL

      total += updated
      logger.info("Batch: #{updated} rows (total: #{total})")
      break if updated.zero? || total >= max_updates
    end

    logger.info("Done. #{total} rows trimmed.")
  end
end
