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

        def self.audit_with_account(account_number)
          original = Thread.current[:audit_account_number]
          Thread.current[:audit_account_number] = account_number
          return unless block_given?

          begin
            yield
          ensure
            Thread.current[:audit_account_number] = original
          end
        end
      end
    end
  end
end
