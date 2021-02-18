# frozen_string_literal: true

require 'audit_log/audit_log'

# Wraps base Rails logger to add audit capabilities.
# The default is set to log into 'log/audit.log`.
# It can be configured with `config.audit_logger`.
def init_audit_logging
  logsetup = Insights::API::Common::AuditLog
  config = Rails.application.config
  audit_logger = if defined?(config.audit_logger)
                   config.audit_logger
                 else
                   logsetup.new_file_logger('log/audit.log')
                 end
  Rails.logger = logsetup.new(Rails.logger, audit_logger)
end

init_audit_logging