# frozen_string_literal: true

# Methods that are related to a profile's policy
module ProfilePolicyAssociation
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_empty_policy
    after_destroy :destroy_policy_test_results

    belongs_to :policy_object, class_name: :Policy, foreign_key: :policy_id,
                               optional: true, inverse_of: :profiles

    def policy
      return self unless external

      Profile.includes(:benchmark)
             .older_than(created_at)
             .find_by(account: account_id, external: false, ref_id: ref_id,
                      benchmarks: { ref_id: benchmark.ref_id })
    end

    def policy_profiles
      return Profile.none if account_id.nil?

      Profile.includes(:benchmark)
             .where(account: account_id, ref_id: ref_id,
                    benchmarks: { ref_id: benchmark.ref_id })
    end

    def business_objective
      BusinessObjective.find(business_objective_id) if business_objective_id
    end

    def business_objective_id
      (policy || self).read_attribute(:business_objective_id)
    end

    def compliance_threshold
      (policy || self).read_attribute(:compliance_threshold)
    end

    def destroy_policy_test_results
      if Settings.async
        DestroyProfilesJob.perform_async(policy_profiles.pluck(:id))
      else
        DestroyProfilesJob.new.perform(policy_profiles.pluck(:id))
      end
    end

    def destroy_empty_policy
      policy_object.destroy if policy_object&.profiles&.empty?
    end
  end
end
