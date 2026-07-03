# frozen_string_literal: true

# Helper methods related to notifications
module Notifications
  extend ActiveSupport::Concern

  included do
    private

    def compliance_notification_wrapper
      # Store the notification preconditions before saving the report
      preconditions = policy_previously_compliant? || policy_untested?

      yield

      # Produce a notification if preconditions are met and the new score is below threshold
      return unless parser.supported? && preconditions && parser.score < parser.policy.compliance_threshold

      notify_non_compliant!
      Rails.logger.info('Notification emitted due to non-compliance')
    end

    # Notifications should be only allowed if there are no test results or the policy was previously compliant
    def policy_previously_compliant?
      tr = last_test_result
      tr && tr.score >= parser.policy.compliance_threshold
    end

    def policy_untested?
      last_test_result.nil?
    end

    def notify_non_compliant!
      SystemNonCompliant.deliver(
        system: parser.system,
        org_id: @msg_value['org_id'],
        policy: parser.policy,
        compliance_score: parser.score
      )
    end

    def last_test_result
      @last_test_result ||= TestResult
                            .where(system: parser.system, tailoring: parser.tailoring)
                            .order(end_time: :desc)
                            .first
    end
  end
end
