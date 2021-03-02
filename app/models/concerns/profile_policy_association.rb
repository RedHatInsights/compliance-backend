# frozen_string_literal: true

# Methods that are related to a profile's policy
module ProfilePolicyAssociation
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_policy_with_internal
    after_destroy :destroy_empty_policy

    belongs_to :policy, optional: true, inverse_of: :profiles
    has_many :policy_test_results, through: :policy,
                                   source: :test_results
    has_many :policy_test_result_hosts, -> { distinct },
             through: :policy_test_results, source: :host
    delegate :business_objective, :business_objective_id,
             to: :policy, allow_nil: true
    validate :no_duplicate_policy_types, on: :create

    def policy_profile
      policy&.initial_profile
    end

    def policy_profile_id
      policy_profile&.id
    end

    def no_duplicate_policy_types
      return if canonical? || external

      error_msg = 'must be unique. Another policy with '\
                  'this policy type already exists.'
      profile = Profile.includes(:benchmark).find_by(
        ref_id: ref_id, account: account, external: false,
        benchmarks: { ref_id: benchmark.ref_id }
      )

      errors.add(:policy_type, error_msg) if profile
    end

    def compliance_threshold
      policy&.compliance_threshold ||
        Policy::DEFAULT_COMPLIANCE_THRESHOLD
    end

    def destroy_policy_with_internal
      return if external?

      destroyed_policy = policy&.destroy
      audit_policy_with_main_autoremove(destroyed_policy)
    end

    def destroy_empty_policy
      return unless policy&.profiles&.empty?

      destroyed_policy = policy.destroy
      audit_empty_policy_autoremove(destroyed_policy)
    end

    private

    def audit_policy_with_main_autoremove(policy)
      return unless policy

      msg = "Autoremoved policy #{policy.id} with the initial/main profile"
      Rails.logger.audit_success(msg)
    end

    def audit_empty_policy_autoremove(policy)
      msg = "Autoremoved policy #{policy.id} with the last profile"
      Rails.logger.audit_success(msg)
    end
  end
end
