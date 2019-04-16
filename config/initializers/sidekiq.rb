Sidekiq.configure_server do |config|
  Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
  config.redis = {
    url: "redis://#{Settings.redis_url}",
    network_timeout: 5 # Default is 1 second, let's be more lenient
  }
end

Sidekiq.configure_client do |config|
  Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
  config.redis = {
    url: "redis://#{Settings.redis_url}",
    network_timeout: 5
  }
end

Sidekiq.default_worker_options = { 'backtrace' => true, 'retry' => 3, 'unique' => true }
