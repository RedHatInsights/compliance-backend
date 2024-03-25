# frozen_string_literal: true

module Insights
  module Api
    module Common
      # Additional helper methods for audit logging
      class LoggerWithAudit < ActiveSupport::Logger
        def audit_success(message)
          tagged('AUDIT - SUCCESS') do |logger|
            logger.info(message)
          end
        end

        def audit_fail(message)
          tagged('AUDIT - FAIL') do |logger|
            logger.info(message)
          end
        end

        # Mask tagged logging for CloudWatchLogger as it is not supported there
        # :nocov:
        # unless defined?(tagged)
        #   define_method(:tagged) do |_prefix, &block|
        #     block.call(self)
        #   end
        # end
        # :nocov:
      end
    end
  end
end
