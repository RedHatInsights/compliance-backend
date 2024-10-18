# frozen_string_literal: true

namespace :db do
  desc 'Reindex the database, including the inventory table'
  task reindex: [:environment] do
    [
      'REINDEX (VERBOSE, CONCURRENTLY) SCHEMA inventory',
      'REINDEX (VERBOSE, CONCURRENTLY) SCHEMA public',
      'VACUUM (VERBOSE, ANALYZE)'
    ].each do |query|
      Rails.logger.info(query)
      ActiveRecord::Base.connection.execute(query)
    end
  end
end
