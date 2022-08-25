# frozen_string_literal: true

require_relative 'audit_log/wrapped_logger'
require_relative 'audit_log/formatter'
require_relative 'audit_log/middleware'

# Common space for Insights API stuff
module Insights
  module API
    module Common
      # Audit Logger into selected logger, but primarily to CloudWatch
      module AuditLog
        def self.new(base_logger, audit_logger = nil)
          WrappedLogger.new(base_logger, audit_logger)
        end

        def self.new_file_logger(filepath, autoflush = true)
          f = File.open(filepath, 'a')
          f.binmode
          f.sync = autoflush

          args = Rails.env.production? ? [f] : [f, 1, 64.megabytes]
          ::Logger.new(*args)
        end

        def self.audit_with_account(org_id)
          original = Thread.current[:audit_org_id]
          Thread.current[:audit_org_id] = org_id
          return unless block_given?

          begin
            yield
          ensure
            Thread.current[:audit_org_id] = original
          end
        end
      end
    end
  end
end
