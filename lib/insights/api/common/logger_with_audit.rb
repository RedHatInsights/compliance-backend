# frozen_string_literal: true

module Insights
  module Api
    module Common
      # Additional helper methods for audit logging
      class LoggerWithAudit < ActiveSupport::Logger
        def audit_success(message)
          info("[AUDIT - SUCCESS] #{message}")
        end

        def audit_fail(message)
          info("[AUDIT - FAIL] #{message}")
        end
      end
    end
  end
end
