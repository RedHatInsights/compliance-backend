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

    # Lookup up internal profile that has the host(s)
    # assinged to a policy an which matches the ref_id
    # and ref_id of a benchmark (to ensure major OS version)
    def find_policy(hosts: test_result_hosts, account: account_id)
      Profile.includes(:benchmark, :policy_hosts)
             .where(policy_hosts: { host_id: hosts })
             .find_by(account: account, external: false, ref_id: ref_id,
                      benchmarks: { ref_id: benchmark.ref_id })
    end

    def compliance_threshold
      policy_object&.compliance_threshold ||
        Policy::DEFAULT_COMPLIANCE_THRESHOLD
    end

    def destroy_with_policy
      transaction do
        destroyed = destroy
        destroyed&.policy_object&.destroy
        destroyed
      end
    end

    def destroy_empty_policy
      policy_object.destroy if policy_object&.profiles&.empty?
    end
  end
end
