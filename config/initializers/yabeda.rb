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
  end

  Yabeda::Prometheus::Exporter.start_metrics_server!
end
