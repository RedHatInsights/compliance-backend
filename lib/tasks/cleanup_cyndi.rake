# frozen_string_literal: true

namespace :cyndi do
  desc 'Remove leftover Cyndi DB objects (schema/view/table) and roles. Dry-run unless CONFIRM=true.'
  task cleanup: :environment do
    confirm = ENV['CONFIRM'] == 'true'
    drop_roles = ENV['DROP_ROLES'] == 'true'

    logger = Logger.new($stdout)
    mode = confirm ? 'EXECUTE' : 'DRY RUN'
    logger.info("cyndi:cleanup started. Mode: #{mode} | DROP_ROLES: #{drop_roles}")

    CyndiCleaner.new(logger: logger).run(confirm: confirm, drop_roles: drop_roles)
  end
end
