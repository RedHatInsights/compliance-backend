# frozen_string_literal: true

# A service class to merge duplicate Xccdf::Benchmark objects
class DuplicateBenchmarkResolver
  class << self
    def run!
      @benchmarks = nil
      duplicate_benchmarks.find_each do |bm|
        if existing_benchmark(bm)
          migrate_benchmark(existing_benchmark(bm), bm)
        else
          self.existing_benchmark = bm
        end
      end
    end

    private

    def existing_benchmark(benchmark)
      benchmarks[[benchmark.ref_id, benchmark.version]]
    end

    def existing_benchmark=(benchmark)
      benchmarks[[benchmark.ref_id, benchmark.version]] = benchmark
    end

    def benchmarks
      @benchmarks ||= {}
    end

    def duplicate_benchmarks
      Xccdf::Benchmark.joins(
        "JOIN (#{grouped_nonunique_benchmark_tuples.to_sql}) as bm on "\
        'benchmarks.ref_id = bm.ref_id AND '\
        'benchmarks.version = bm.version'
      )
    end

    def grouped_nonunique_benchmark_tuples
      Xccdf::Benchmark.select(:ref_id, :version)
                      .group(:ref_id, :version)
                      .having('COUNT(id) > 1')
    end

    def migrate_benchmark(existing_bm, duplicate_bm)
      logger.info(
        "Duplicate benchmark found for #{existing_bm.id} - #{duplicate_bm.id}"
      )
      migrate_rules(existing_bm, duplicate_bm)
      migrate_parent_profiles(existing_bm, duplicate_bm)
      migrate_profiles(existing_bm, duplicate_bm)
      remove_remaining_parent_profiles(duplicate_bm)
      duplicate_bm.destroy # Rules, Profiles
    end

    # rubocop:disable Rails/SkipsModelValidations
    def migrate_rules(existing_bm, duplicate_bm)
      logger.info(
        "Migrating rules for #{existing_bm.id} - #{duplicate_bm.id}..."
      )
      duplicate_bm.rules.where.not(ref_id: existing_bm.rules.select(:ref_id))
                  .update_all(benchmark_id: existing_bm.id)
    end

    def migrate_parent_profiles(existing_bm, duplicate_bm)
      duplicate_bm.profiles.where.not(
        ref_id: existing_bm.profiles.select(:ref_id),
        parent_profile_id: nil
      ).find_each do |profile|
        profile.update!(
          parent_profile: existing_bm.profiles.canonical.find_by!(
            ref_id: profile.parent_profile.ref_id
          )
        )
      end
    end

    def remove_remaining_parent_profiles(duplicate_bm)
      duplicate_bm.profiles.where.not(parent_profile_id: nil)
                  .update_all(parent_profile_id: nil)
    end

    def migrate_profiles(existing_bm, duplicate_bm)
      logger.info(
        "Migrating profiles for #{existing_bm.id} - #{duplicate_bm.ref_id}..."
      )
      duplicate_bm.profiles.where.not(
        ref_id: existing_bm.profiles.select(:ref_id)
      ).update_all(benchmark_id: existing_bm.id)
    end
    # rubocop:enable Rails/SkipsModelValidations

    def logger
      Rails.logger
    end
  end
end
