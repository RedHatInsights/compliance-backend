Redis.exists_returns_integer = false # remove on sidekiq upgrade

sidekiq_config = lambda do |config|
  config.redis = {
    url: "redis://#{Settings.redis_url}",
    password: Settings.redis_password.present? ? Settings.redis_password : nil,
    ssl: Settings.redis_ssl,
    network_timeout: 5
  }
  config.options[:dead_timeout_in_seconds] = 2.weeks.to_i
  config.options[:interrupted_timeout_in_seconds] = 2.weeks.to_i

  Sidekiq::ReliableFetch.setup_reliable_fetch!(config) if $0.include?('sidekiq')
end

Sidekiq.configure_server(&sidekiq_config) if $0.include?('sidekiq')

if Rails.env != 'test'
  Sidekiq.configure_client(&sidekiq_config)
  Sidekiq.default_worker_options = { 'backtrace' => true, 'retry' => 3, 'unique' => true }
end
