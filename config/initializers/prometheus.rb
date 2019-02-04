if Rails.env != "test"
  require 'prometheus_exporter/client'
  require 'prometheus_exporter/middleware'
  require 'prometheus_exporter/instrumentation'
  client = PrometheusExporter::Client.new(
    host: Settings.prometheus_exporter_host,
    port: Settings.prometheus_exporter_port
  )
  PrometheusExporter::Client.default = client

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware
  PrometheusExporter::Instrumentation::Process.start(type: "master")
  PrometheusExporter::Instrumentation::Process.start(type: "web")
end
