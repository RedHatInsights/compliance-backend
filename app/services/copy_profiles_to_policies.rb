# frozen_string_literal: true

# A service class to copy Profile data to new Policy objects
class CopyProfilesToPolicies
  class << self
    def run!
      create_policies
    end

    private

    def profiles
      Profile.canonical(false)
             .with_policy(false)
    end

    def create_policies
      profiles.where(external: false).find_each do |profile|
        policy = Policy.find_or_create_by!(Policy.attrs_from(profile: profile))
        policy.host_ids += profile.profile_hosts.pluck(:host_id)
        profiles.where(ref_id: profile.ref_id, account: policy.account).update(
          policy_id: policy.id
        )
      end
    end
  end
end
