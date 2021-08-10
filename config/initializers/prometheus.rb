unless Rails.env.test?
  require 'prometheus_exporter'
  require 'prometheus_exporter/client'
  require 'prometheus_exporter/metric'
  require 'prometheus_exporter/middleware'
  require 'prometheus_exporter/instrumentation'

  def ensure_exporter_server
    require 'socket'
    TCPSocket.open(Settings.prometheus_exporter_host, Settings.prometheus_exporter_port) {}
  rescue Errno::ECONNREFUSED
    start_exporter_server
  end

  def start_exporter_server
    require 'prometheus_exporter/server'

    server = PrometheusExporter::Server::WebServer.new(port: Settings.prometheus_exporter_port)
    server.start

    if $0.include?('puma')
      require './lib/prometheus/graphql_collector'
      require './lib/prometheus/engineering_collector'
      require './lib/prometheus/business_collector'

      server.collector.register_collector(GraphQLCollector.new)
      server.collector.register_collector(EngineeringCollector.new)
      server.collector.register_collector(BusinessCollector.new)
    end
  rescue Errno::EADDRINUSE
  end

  ensure_exporter_server unless $0.include?('prometheus_exporter')

  PrometheusExporter::Client.default = PrometheusExporter::Client.new(
    host: Settings.prometheus_exporter_host,
    port: Settings.prometheus_exporter_port
  )

  PrometheusExporter::Metric::Base.default_prefix = 'compliance'

  # stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  # basic process stats like RSS and GC info
  PrometheusExporter::Instrumentation::Process.start(type: "master")
end
