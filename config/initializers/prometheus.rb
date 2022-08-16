require 'prometheus_exporter'
require 'prometheus_exporter/client'
require 'prometheus_exporter/metric'
require 'prometheus_exporter/middleware'
require 'prometheus_exporter/instrumentation'

def ensure_exporter_server
  require 'socket'
  TCPSocket.open('127.0.0.1', Settings.prometheus_exporter_port) {}
rescue Errno::ECONNREFUSED
  start_exporter_server
end

def start_exporter_server
  require 'prometheus_exporter/server'

  server = PrometheusExporter::Server::WebServer.new(port: Settings.prometheus_exporter_port)
  server.start
  # Increase the server thread priority for better latency
  server.instance_variable_get(:@runner).priority = 3

  require './lib/prometheus/graphql_collector'

  server.collector.register_collector(GraphQLCollector.new)
rescue Errno::EADDRINUSE
end

unless $0.include?('puma')
  ensure_exporter_server unless $0.include?('prometheus_exporter')

  PrometheusExporter::Client.default = PrometheusExporter::Client.new(
    host: '127.0.0.1',
    port: Settings.prometheus_exporter_port
  )

  PrometheusExporter::Metric::Base.default_prefix = 'compliance_'

  # stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  # basic process stats like RSS and GC info
  PrometheusExporter::Instrumentation::Process.start(type: "master")
end
