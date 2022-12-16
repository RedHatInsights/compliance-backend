# Metrics configuration
Yabeda.configure do
  default_tag :application, 'compliance'
  default_tag :qe, 0
  default_tag :gql_op, nil
end

# Start the metrics server for sidekiq and racecar
if %w[sidekiq racecar].any? { |p| $0.include?(p) }
  Yabeda::Prometheus::Exporter.start_metrics_server!
end
