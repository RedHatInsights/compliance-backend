# frozen_string_literal: true

namespace :db do
  desc 'Check for available database connection'
  task status: [:environment] do
    begin
      ActiveRecord::Base.connection
    rescue StandardError # rubocop:disable Lint/SuppressedException
    ensure
      abort('ERROR: Database unavailable') unless ActiveRecord::Base.connected?
    end
  end
end
