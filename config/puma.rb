# frozen_string_literal: true
require 'clowder-common-ruby'

min_threads = ENV.fetch('PUMA_MIN_THREADS', 0).to_i
max_threads = ENV.fetch('PUMA_MAX_THREADS', 5).to_i
concurrency = ENV.fetch('PUMA_WORKERS', 0).to_i

# Specifies the `host` that puma will listen on to receive requests.
set_default_host '0.0.0.0'

# Specifies the `port` that Puma will listen on to receive requests.
if ClowderCommonRuby::Config.clowder_enabled?
  port ClowderCommonRuby::Config.load.webPort
else
  port ENV.fetch('WEB_PORT', 8000)
end

# Specifies the `environment` that Puma will run in.
environment ENV.fetch('RAILS_ENV', 'development')

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE', 'tmp/server.pid')

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma.
threads min_threads, max_threads

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
workers(concurrency)



# Disconnect AR connections before forking so each worker establishes
# its own pool -- avoids sharing sockets across processes.
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

before_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Metrics collection
if ClowderCommonRuby::Config.clowder_enabled?
  ENV['PROMETHEUS_EXPORTER_PORT'] = ClowderCommonRuby::Config.load.metricsPort.to_s
else
  ENV['PROMETHEUS_EXPORTER_PORT'] ||= '9090'
end
activate_control_app("unix://#{File.expand_path(File.join(File.dirname(__FILE__), '../tmp/puma.sock'))}")
plugin :yabeda
plugin :yabeda_prometheus
