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
      duplicate_profiles = profile.account.profiles.where(
        ref_id: profile.ref_id,
        benchmark_id: parent.benchmark.id
      ).count
      return false unless duplicate_profiles >= 1

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
      Profile.where(name: profile.name,
                    ref_id: profile.ref_id,
                    description: profile.description,
                    account_id: nil).or(
                      Profile.where(
                        name: profile.name,
                        ref_id: profile.ref_id,
                        account_id: nil
                      )
                    )
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
