# frozen_string_literal: true

# rubocop:disable Style/Documentation
class SystemsProfileTrimmer
  # rubocop:enable Style/Documentation
  def initialize(batch_size:, max_updates:, logger:)
    @batch_size = batch_size
    @max_updates = max_updates
    @logger = logger
    @total = 0
  end

  def run
    @logger.info("systems:trim_profiles BATCH_SIZE=#{@batch_size} MAX_ROWS_PER_RUN=#{@max_updates}")

    loop do
      remaining = @max_updates - @total
      break if remaining <= 0

      updated = trim_batch([@batch_size, remaining].min)

      @total += updated
      @logger.info("Batch: #{updated} rows (total: #{@total})")
      break if updated.zero?
    end

    @logger.info("Done. #{@total} rows trimmed.")
  end

  private

  # rubocop:disable Metrics/MethodLength
  def trim_batch(limit)
    ActiveRecord::Base.connection.execute(<<-SQL).cmd_tuples
      UPDATE systems SET system_profile = jsonb_strip_nulls(jsonb_build_object(
        'operating_system', system_profile->'operating_system',
        'owner_id',         system_profile->'owner_id'
      ))
      WHERE id IN (
        SELECT id FROM systems
        WHERE jsonb_typeof(system_profile) = 'object'
          AND system_profile - 'operating_system' - 'owner_id' <> '{}'::jsonb
        LIMIT #{limit}
      )
    SQL
  end
  # rubocop:enable Metrics/MethodLength
end

namespace :systems do
  desc 'Strip bloated system_profile JSONB down to operating_system + owner_id'
  task trim_profiles: :environment do
    batch_size = Integer(ENV.fetch('BATCH_SIZE', '1000'))
    max_updates = Integer(ENV.fetch('MAX_ROWS_PER_RUN', '100000'))
    raise ArgumentError, 'BATCH_SIZE must be positive' unless batch_size.positive?
    raise ArgumentError, 'MAX_ROWS_PER_RUN must be positive' unless max_updates.positive?

    SystemsProfileTrimmer.new(
      batch_size: batch_size,
      max_updates: max_updates,
      logger: Logger.new($stdout)
    ).run
  end
end
