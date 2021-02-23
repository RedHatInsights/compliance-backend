# frozen_string_literal: true

require 'audit_log/audit_log'

# Wraps base Rails logger to add audit capabilities.
# The default is set to log into 'log/audit.log`.
# It can be configured with `config.audit_logger`.
def init_audit_logging
  logsetup = Insights::API::Common::AuditLog
  audit_logger =
    configured_audit_logger || logsetup.new_file_logger('log/audit.log')
  Rails.logger = logsetup.new(Rails.logger, audit_logger)
end

def configured_audit_logger
  Rails.application.config.audit_logger
rescue NoMethodError
  nil
end

init_audit_logging
