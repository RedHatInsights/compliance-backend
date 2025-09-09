# frozen_string_literal: true

namespace :db do
  desc 'Check for available database connection'
  task status: [:environment] do
    begin
      ActiveRecord::Base.connection
    rescue => _e # rubocop:disable Style/RescueStandardError
      abort('ERROR: Database unavailable')
    end
  end
end

namespace :redis do
  desc 'Check for available redis connection'
  task status: [:environment] do
    begin
      Redis.new(
        url: Settings.redis.url,
        password: Settings.redis.password.presence,
        ssl: ActiveModel::Type::Boolean.new.cast(Settings.redis.ssl)
      ).ping
    rescue Redis::BaseError
      abort('ERROR: Redis unavailable')
    end
  end
end

namespace :kafka do
  desc 'Check for available kafka connection'
  task status: [:environment] do
    begin
      ApplicationProducer.ping
    rescue StandardError
      abort('ERROR: Kafka unavailable')
    end
  end
end
