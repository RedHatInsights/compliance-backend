# frozen_string_literal: true

# A service class to associate profiles to their parent profiles
class ParentProfileAssociator
  class << self
    def run!
      Profile.transaction do
        Profile.where.not(account: nil).find_each do |profile|
          parent = find_parent(profile)
          next if profile_already_in_account!(profile, parent)

          profile.update!(parent_profile: parent, benchmark: parent.benchmark)
        end
      end
    end

    private

    def profile_already_in_account!(profile, parent)
      possible_duplicate_profiles = profile.account.profiles.where(
        ref_id: profile.ref_id,
        benchmark_id: parent.benchmark.id
      )
      # If multiple profiles are returned with the same ref_id and prospective
      # benchmark_id, `.update!` will not be able to run. If only 1 profile is
      # found with these ref_id/benchmark_id - it's the same one we're passing
      # as an argument, so it's not a problem to keep it. Otherwise, remove it
      # as there's a profile already in the account with the right attributes.
      return false if (possible_duplicate_profiles.count == 1 &&
                       possible_duplicate_profiles.include?(profile)) ||
                      possible_duplicate_profiles.count == 0

      profile.delete_all_test_results = true
      profile.destroy
    end

    def find_parent(profile)
      logger.info("Finding parents for profile #{profile.id}")
      parents = find_in_same_benchmark(profile)
      parents = find_in_other_benchmarks(profile) if parents.blank?

      raise not_found(profile) unless parents.any?

      parent = find_most_recent_parent(parents)
      logger.info("Found parent #{parent.id} for profile #{profile.id}")
      parent
    end

    def find_in_same_benchmark(profile)
      Profile.where(ref_id: profile.ref_id,
                    benchmark_id: profile.benchmark_id,
                    account_id: nil)
    end

    # Profiles in the phony-benchmark will have to be assigned to
    # a real benchmark if it can be found.
    def find_in_other_benchmarks(profile)
      parent_matching_description = Profile.where(
        name: profile.name,
        ref_id: profile.ref_id,
        description: profile.description,
        account_id: nil
      )
      return parent_matching_description if parent_matching_description.present?

      Profile.where(name: profile.name, ref_id: profile.ref_id, account_id: nil)
    end

    def find_most_recent_parent(parents)
      latest_benchmark = ::Xccdf::Benchmark.find_latest(
        parents.map(&:benchmark)
      )
      parents.find { |p| p.benchmark == latest_benchmark }
    end

    def not_found(profile)
      ActiveRecord::RecordNotFound.new(
        "Failed to find parent for profile with ID #{profile.id}."
      )
    end

    def logger
      Rails.logger
    end
  end
end
