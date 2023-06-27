# frozen_string_literal: true
require 'clowder-common-ruby'

min_threads = ENV.fetch('PUMA_MIN_THREADS', 0).to_i
max_threads = ENV.fetch('PUMA_MAX_THREADS', 16).to_i
concurrency = ENV.fetch('PUMA_WORKERS', 0).to_i

# Specifies the `host` that puma will listen on to receive requests
#
set_default_host '0.0.0.0'

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ClowderCommonRuby::Config.load.webPort

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV', 'development')

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE', 'tmp/server.pid')

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads min_threads, max_threads

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers(concurrency)

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app! if concurrency > 0

# Allow puma to be restarted by `rails restart` command.
# plugin :tmp_restart

# Metrics collection
#
activate_control_app("unix://#{File.expand_path(File.join(File.dirname(__FILE__), '../tmp/puma.sock'))}")
plugin :yabeda
plugin :yabeda_prometheus
