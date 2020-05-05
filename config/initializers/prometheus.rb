if Rails.env != "test" && !$0.include?('prometheus_exporter')
  require 'prometheus_exporter/client'
  require 'prometheus_exporter/metric'
  require 'prometheus_exporter/middleware'
  require 'prometheus_exporter/instrumentation'
  client = PrometheusExporter::Client.new(
    host: Settings.prometheus_exporter_host,
    port: Settings.prometheus_exporter_port
    # Add custom_labels for app_name here (consumer and webserver)
  )
  PrometheusExporter::Metric::Base.default_prefix = 'compliance'
  PrometheusExporter::Client.default = client

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware
  PrometheusExporter::Instrumentation::Process.start(type: "master")
  PrometheusExporter::Instrumentation::Process.start(type: "web")
end
