# frozen_string_literal: true

# Methods that are related to a profile's policy
module ProfilePolicyAssociation
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_empty_policy

    belongs_to :policy_object, class_name: :Policy, foreign_key: :policy_id,
                               optional: true, inverse_of: :profiles
    delegate :business_objective, :business_objective_id, :update_hosts,
             to: :policy_object, allow_nil: true

    def old_policy
      return if canonical?

      Profile.includes(:benchmark, :policy_hosts)
             .older_than(created_at)
             .where(policy_hosts: { host_id: test_result_hosts })
             .find_by(account: account_id, external: false, ref_id: ref_id,
                      benchmarks: { ref_id: benchmark.ref_id,
                                    version: benchmark.latest_ssg }) || self
    end

    def old_policy_profiles
      return Profile.none if account_id.nil?

      Profile.includes(:benchmark)
             .where(account: account_id, ref_id: ref_id,
                    benchmarks: { ref_id: benchmark.ref_id })
    end

    def compliance_threshold
      policy_object&.compliance_threshold ||
        Policy::DEFAULT_COMPLIANCE_THRESHOLD
    end

    def destroy_empty_policy
      policy_object.destroy if policy_object&.profiles&.empty?
    end
  end
end
