# frozen_string_literal: true

namespace :tailorings do
  desc 'Remove NULL os_minor_version and race-condition duplicate tailorings, and their dependent records. ' \
       'Dry run by default; pass CONFIRM=true to actually delete.'
  task cleanup_duplicates: :environment do
    logger = Logger.new($stdout)
    cleaner = DuplicateTailoringsCleaner.new(logger: logger)
    plan = cleaner.plan

    if plan.fetch('tailorings').zero?
      logger.info('tailorings:cleanup_duplicates: nothing to clean up.')
      next
    end

    unless ENV['CONFIRM'] == 'true'
      logger.info(
        'tailorings:cleanup_duplicates: dry run only, no data was changed. ' \
        'Re-run with CONFIRM=true to perform the deletion.'
      )
      next
    end

    result = cleaner.run!
    logger.info("tailorings:cleanup_duplicates: done. Deleted #{result.fetch('tailorings')} tailorings.")
  end
end
