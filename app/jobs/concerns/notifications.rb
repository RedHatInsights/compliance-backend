# frozen_string_literal: true

# Helper methods related to notifications
module Notifications
  extend ActiveSupport::Concern

  included do
    private

    def compliance_notification_wrapper
      # Store the notification preconditions before saving the report
      preconditions = build_notify_preconditions

      yield

      # Produce a notification if preconditions are met and the new score is below threshold
      return unless preconditions && parser.score < parser.policy.compliance_threshold

      notify_non_compliant!
      Rails.logger.info('Notification emitted due to non-compliance')
    end

    # Notifications should be only allowed if there are no test results or the policy was previously compliant
    def build_notify_preconditions
      parser.policy&.compliant?(parser.host) || parser.policy&.test_result_hosts&.where(id: parser.host.id)&.empty?
    end

    def notify_non_compliant!
      SystemNonCompliant.deliver(
        host: parser.host,
        account_number: @msg_value['account'],
        policy: parser.policy,
        policy_threshold: parser.policy.compliance_threshold,
        compliance_score: parser.score
      )
    end
  end
end
