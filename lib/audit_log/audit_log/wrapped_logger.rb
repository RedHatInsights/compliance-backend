# frozen_string_literal: true

# Common space for Insights API stuff
module Insights
  module API
    module Common
      module AuditLog
        # Wrapper and combiner of a base and audit logger
        class WrappedLogger
          AUDIT_SUCCESS = 'success'
          AUDIT_FAIL = 'fail'

          attr_reader :base_logger

          delegate :add, :debug, :info, :warn, :error, :fatal,
                   :datetime_format, :datetime_format=,
                   to: :base_logger

          def initialize(base_logger, audit_logger = nil)
            @base_logger = base_logger
            @audit_logger = init_logger(audit_logger)
          end

          def audit(payload)
            @audit_logger.info(payload)
          end

          def audit_success(payload)
            payload = hash_payload(payload).merge(status: AUDIT_SUCCESS)
            audit(payload)
          end

          def audit_fail(payload)
            payload = hash_payload(payload).merge(status: AUDIT_FAIL)
            audit(payload)
          end

          def audit_with_account(account_number, &block)
            AuditLog.audit_with_account(account_number, &block)
          end

          def close
            send_both(:close)
          end

          def reopen
            send_both(:reopen)
          end

          def method_missing(symbol, *args, &block)
            if respond_to_missing?(symbol)
              @base_logger.public_send(symbol, *args, &block)
            else
              super
            end
          end

          def respond_to_missing?(name, include_private = false)
            @base_logger.respond_to?(name) || super
          end

          private

          def send_both(symbol, *args)
            [@base_logger, @audit_logger].each do |logger|
              logger.public_send(symbol, *args)
            end
          end

          def init_logger(logger = nil)
            logger ||= Logger.new($stdout)
            logger.level = Logger::INFO
            logger.formatter = Formatter.new
            logger
          end

          def hash_payload(payload)
            return payload if payload.is_a?(Hash)

            { message: payload }
          end
        end
      end
    end
  end
end
