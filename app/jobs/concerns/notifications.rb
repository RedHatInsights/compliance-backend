# frozen_string_literal: true

# Helper methods related to notifications
module Notifications
  extend ActiveSupport::Concern

  included do
    private

    def compliance_notification_wrapper
      # Store the old score to detect if there was a drop or there are no test results
      pre_compliant = parser.host.test_results.empty? || parser.policy.compliant?(parser.host)

      yield

      # Produce a notification if there score drop was not caused by this report
      notify_non_compliant! if pre_compliant && parser.score < parser.policy.compliance_threshold
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
