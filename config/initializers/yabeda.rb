require 'clowder-common-ruby'

# Metrics configuration
Yabeda.configure do
  default_tag :application, 'compliance'
  default_tag :qe, 0
  # APIv2 specific tags
  # default_tag :path, nil
  default_tag :source, 'basic'
end

# Start the metrics server for sidekiq and karafka
if %w[sidekiq karafka].any? { |p| $0.include?(p) }
  if ClowderCommonRuby::Config.clowder_enabled?
    ENV['PROMETHEUS_EXPORTER_PORT'] = ClowderCommonRuby::Config.load.metricsPort.to_s
  else
    ENV['PROMETHEUS_EXPORTER_PORT'] ||= '9090'
  end

  Yabeda::ActiveJob.install!
  Yabeda::Prometheus::Exporter.start_metrics_server!
end
