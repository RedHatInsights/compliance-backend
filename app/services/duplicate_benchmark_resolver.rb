# frozen_string_literal: true

# A service class to merge duplicate Xccdf::Benchmark objects
class DuplicateBenchmarkResolver
  class << self
    def run!
      each_benchmark do |bm|
        if benchmarks[[bm.ref_id, bm.version]]
          migrate_benchmark(benchmarks[[bm.ref_id, bm.version]], bm)
        else
          benchmarks[[bm.ref_id, bm.version]] = bm
        end
      end
    end

    private

    def migrate_benchmark(existing_bm, duplicate_bm)
      migrate_rules(existing_bm, duplicate_bm)
      migrate_profiles(existing_bm, duplicate_bm)
      duplicate_bm.delete
    end

    def each_benchmark
      Xccdf::Benchmark.includes(:rules, :profiles).find_each do |bm|
        Xccdf::Benchmark.transaction do
          yield bm
        end
      end
    end

    def benchmarks
      @benchmarks ||= {}
    end

    # rubocop:disable Rails/SkipsModelValidations
    # we expect validations to fail due to nonunique rules/profiles
    # accept duplicate rules for now
    def migrate_rules(existing_bm, duplicate_bm)
      duplicate_bm.rules.update_all(benchmark_id: existing_bm.id)
    end

    # accept duplicate profiles for now
    def migrate_profiles(existing_bm, duplicate_bm)
      duplicate_bm.profiles.update_all(benchmark_id: existing_bm.id)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
