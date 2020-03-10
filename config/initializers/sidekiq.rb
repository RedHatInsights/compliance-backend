sidekiq_config = lambda do |config|
  config.redis = {
    url: "redis://#{Settings.redis_url}",
    network_timeout: 5
  }
  Sidekiq::ReliableFetch.setup_reliable_fetch!(config)

  config.server_middleware do |chain|
    require 'prometheus_exporter/instrumentation'
    chain.add PrometheusExporter::Instrumentation::Sidekiq
  end
  config.on :startup do
    require 'prometheus_exporter/instrumentation'
    PrometheusExporter::Instrumentation::Process.start type: 'sidekiq'
  end
  config.death_handlers << PrometheusExporter::Instrumentation::Sidekiq.death_handler

  at_exit do
    PrometheusExporter::Client.default.stop(wait_timeout_seconds: 10)
  end
end

if $0.include?('sidekiq')
  Sidekiq.configure_server(&sidekiq_config)
end

if Rails.env != 'test'
  Sidekiq.configure_client(&sidekiq_config)
  Sidekiq.default_worker_options = { 'backtrace' => true, 'retry' => 3, 'unique' => true }
end
