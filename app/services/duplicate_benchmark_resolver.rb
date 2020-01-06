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
      duplicate_bm.destroy! # profiles, rules
    end

    def each_benchmark
      Xccdf::Benchmark.transaction do
        Xccdf::Benchmark.includes(:rules, :profiles).find_each do |bm|
          yield bm
        end
      end
    end

    def benchmarks
      @benchmarks ||= {}
    end

    def migrate_rules(existing_bm, duplicate_bm)
      duplicate_bm.rules.find_each do |rule|
        if existing_bm.rules.pluck(:ref_id).include?(rule.ref_id)
          migrate_rule(existing_bm.rules.find_by(ref_id: rule.ref_id), rule)
        else
          rule.update!(benchmark_id: existing_bm.id)
        end
      end
    end

    def migrate_rule(existing_rule, duplicate_rule)
      duplicate_rule.rule_results.update(rule_id: existing_rule.id)
      duplicate_rule
        .destroy # profile_rules, rule_references_rules, rule_identifier
    end

    def migrate_profiles(existing_bm, duplicate_bm)
      duplicate_bm.profiles.find_each do |profile|
        if existing_bm.profiles.pluck(:ref_id, :account_id)
                      .include?([profile.ref_id, profile.account_id])
          migrate_profile(existing_bm.profiles.find_by(ref_id: profile.ref_id),
                          profile)
        else
          profile.update!(benchmark_id: existing_bm.id)
        end
      end
    end

    def migrate_profile(existing_profile, duplicate_profile)
      duplicate_profile.profile_hosts.update(
        profile_id: existing_profile.id
      )
      duplicate_profile.destroy # profile_rules, profile_hosts
    end
  end
end
