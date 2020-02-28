# frozen_string_literal: true

# A service class to associate profiles to their parent profiles
class ParentProfileAssociator
  class << self
    def run!
      Profile.transaction do
        Profile.where.not(account: nil).find_each do |profile|
          profile.update!(parent_profile: find_parent(profile))
        end
      end
    end

    private

    def find_parent(profile)
      parents = Profile.where(ref_id: profile.ref_id,
                              benchmark_id: profile.benchmark_id,
                              account_id: nil)
      raise not_found(profile) unless parents.one?

      parents.first
    end

    def not_found(profile)
      ActiveRecord::RecordNotFound.new(
        "Failed to find parent for profile with ID #{profile.id}."
      )
    end
  end
end
