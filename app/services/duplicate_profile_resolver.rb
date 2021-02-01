# frozen_string_literal: true

# A service class to merge duplicate Profile objects
class DuplicateProfileResolver
  class << self
    def run!
      @profiles = nil
      duplicate_profiles.find_each do |profile|
        if existing_profile(profile)
          migrate_profile(existing_profile(profile), profile)
        else
          self.existing_profile = profile
        end
      end
    end

    private

    def existing_profile(profile)
      profiles[[profile.ref_id, profile.account_id, profile.benchmark_id]]
    end

    def existing_profile=(profile)
      profiles[[profile.ref_id,
                profile.account_id,
                profile.benchmark_id]] = profile
    end

    def profiles
      @profiles ||= {}
    end

    def migrate_profile(existing_p, duplicate_p)
      migrate_test_results(existing_p, duplicate_p)
      migrate_child_profiles(existing_p, duplicate_p)
      duplicate_p.destroy # BusinessObjectives, ProfileRules
    end

    def duplicate_profiles
      Profile.joins(
        "JOIN (#{grouped_nonunique_profile_tuples.to_sql}) as p on "\
        'profiles.ref_id = p.ref_id AND '\
        'profiles.account_id is not distinct from p.account_id AND '\
        'profiles.benchmark_id = p.benchmark_id'
      )
    end

    def grouped_nonunique_profile_tuples
      Profile.select(:ref_id, :account_id, :benchmark_id)
             .group(:ref_id, :account_id, :benchmark_id)
             .having('COUNT(id) > 1')
    end

    # rubocop:disable Rails/SkipsModelValidations
    def migrate_test_results(existing_p, duplicate_p)
      duplicate_p.test_results.update_all(profile_id: existing_p.id)
    end

    def migrate_child_profiles(existing_p, duplicate_p)
      Profile.where(parent_profile: duplicate_p)
             .update_all(parent_profile_id: existing_p.id)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
