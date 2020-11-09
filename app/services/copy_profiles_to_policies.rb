# frozen_string_literal: true

# A service class to copy Profile data to new Policy objects
class CopyProfilesToPolicies
  class << self
    delegate :run!, to: :new
  end

  def run!
    create_policies
  end

  private

  def profiles
    Profile.canonical(false)
           .with_policy(false)
  end

  # Create a Policy for each non-canonical internal Profile,
  # assign the same hosts set.
  def create_policies
    profiles.where(external: false).find_each do |profile|
      policy = Policy.create!(Policy.attrs_from(profile: profile))
      profile.update!(policy_id: policy.id, business_objective_id: nil)

      host_ids = profile.profile_hosts.distinct.pluck(:host_id)
      PolicyHost.create(
        host_ids.map do |host_id|
          { policy_id: policy.id, host_id: host_id }
        end
      )
    end
  end
end
