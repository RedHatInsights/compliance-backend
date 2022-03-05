# frozen_string_literal: true

# Helper methods related to notifications
module Notifications
  extend ActiveSupport::Concern

  included do
    private

    def compliance_notification_wrapper
      # Store the old score to detect if there was a drop
      pre_compliant = parser.policy.compliant?(parser.host)

      yield

      # Produce a notification if there is no previos report or the host was compliant before
      notify_non_compliant! if (no_test_results? || pre_compliant) && parser.score < parser.policy.compliance_threshold
    end

    def no_test_results?
      parser.policy.test_result_hosts.where(id: parser.host.id).empty?
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
