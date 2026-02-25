# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV.fetch('RAILS_LOGLEVEL', :info).to_sym

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :request_id ]

  # Use in memory cache store in foreman.
  config.cache_store = :memory_store, { size: 64.megabytes }

  # Logging configuration might be coming from env variables that are only available after initialization
  config.after_initialize do
    # Set up cloudwatch logging if available
    # FIXME: change this to `Settings.logging.type == "cloudwatch"` once Clowder supports the configuration
    #
    # https://github.com/RedHatInsights/clowder/blob
    #   /9a5b2bea2009911cebbddd0ed440a8b360014e64/controllers/cloud.redhat.com/providers/logging/appinterface.go#L54
    if Settings.logging&.credentials&.access_key_id.present?
      $cloudwatch_client ||= CloudWatchLogger::Client.new(
        Settings.logging.credentials,
        Settings.logging.log_group,
        ENV.fetch('LOGSTREAM').presence || Socket.gethostname, # logstream name falls back to hostname if unset in ENV
        region: Settings.logging.region
      )
      cloudwatch_logger = Insights::Api::Common::LoggerWithAudit.new($cloudwatch_client)
      cloudwatch_logger.formatter = $cloudwatch_client.formatter(:json)
      config.logger.broadcast_to(cloudwatch_logger)
      cloudwatch_logger.level = Logger::WARN # Different logging level for CloudWatch
    end
  end

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "compliance-backend_#{Rails.env}"

  # config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Log disallowed deprecations.
  config.active_support.disallowed_deprecation = :log

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    config.logger = Insights::Api::Common::LoggerWithAudit.new(STDOUT)
    config.logger.formatter = config.log_formatter
  else
    config.logger = Insights::Api::Common::LoggerWithAudit(config.paths['log'].first)
  end
  config.logger = ActiveSupport::BroadcastLogger.new(config.logger)

  # Temporarily allow any origins
  config.hosts.clear
  # # Production, stage and ephemeral environments
  # config.hosts << /(cloud|console)\.(stage\.)?redhat\.com\z/
  # # Ephemeral environments
  # config.hosts << /.+.apps\.c-rh-c-eph\.(\w+)\.p1\.openshiftapps\.com\z/
  # config.hosts << /\Acompliance-service\z/
  # # Kubernetes readiness/liveness probe
  # config.hosts << /\A10\.\d+\.\d+\.\d+\z/

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
