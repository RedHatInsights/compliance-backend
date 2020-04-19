module CacheHelper
  class << self
    def warm
      Profile.find_each do |profile|
        warm_profile(profile)
      end
      ::Xccdf::Benchmark.find_each do |benchmark|
        warm_benchmark(benchmark)
      end
      Host.find_each do |host|
        warm_host(host)
      end
    end

    def warm_host(host)
      Rails.cache.write(
        { host: host.id, attribute: 'rule_objects_failed' },
        ::Rule.where(
          id: ::RuleResult.failed.for_system(host.id)
          .includes(:rule).pluck(:rule_id).uniq
        )
      )
      host.profiles.find_each do |profile|
        Rails.cache.write(
          { profile: profile.id, host: host.id, attribute: 'results' },
          profile.results(host)
        )
        Rails.cache.write(
          { profile: profile.id, host: host.id, attribute: 'rules_passed' },
          host.rules_passed(profile)
        )
        Rails.cache.write(
          { profile: profile.id, host: host.id, attribute: 'rules_failed' },
          host.rules_passed(profile)
        )
        Rails.cache.write(
          { profile: profile.id, host: host.id, attribute: 'score' },
          profile.score(host: host)
        )
      end
    end

    def warm_profile(profile)
      Rails.cache.write({ profile: profile.id, relation: 'rules' }, profile.rules)
      profile.rules.find_each do |rule|
        Rails.cache.write(
          { rule: rule.id, attribute: 'references' },
          rule.references.map { |ref| [ref.href, ref.label] }.to_json
        )
        Rails.cache.write(
          { rule: rule.id, attribute: 'identifier' },
          { label: rule.identifier&.label, system: rule.identifier&.system }.to_json
        )
        Rails.cache.write(
          { rule: rule.id, relation: 'profiles' },
          rule.profiles
        )
      end
    end

    def warm_benchmark(benchmark)
      Rails.cache.write({ benchmark: benchmark.id, relation: 'rules' }, benchmark.rules)
      Rails.cache.write({ benchmark: benchmark.id, relation: 'canonical_profiles' }, benchmark.profiles.canonical)
    end

    def invalidate
      Host.find_each do |host|
        invalidate_host(host)
      end
      Profile.find_each do |profile|
        invalidate_profile(profile)
      end
      ::Xccdf::Benchmark.find_each do |benchmark|
        invalidate_benchmark(benchmark)
      end
    end

    def invalidate_host(host)
      Rails.cache.delete(host: host.id, attribute: 'rule_objects_failed')
      host.profiles.find_each do |profile|
        Rails.cache.delete(profile: profile.id, host: host.id, attribute: 'results')
        Rails.cache.delete(profile: profile.id, host: host.id, attribute: 'rules_passed')
        Rails.cache.delete(profile: profile.id, host: host.id, attribute: 'rules_failed')
        Rails.cache.delete(profile: profile.id, host: host.id, attribute: 'score')
      end
    end

    def invalidate_profile(profile)
      Rails.cache.delete(profile: profile.id, relation: 'rules')
      profile.rules.each do |rule|
        Rails.cache.delete(rule: rule.id, attribute: 'references')
        Rails.cache.delete(rule: rule.id, attribute: 'identifier')
        Rails.cache.delete(rule: rule.id, relation: 'profiles')
      end
    end

    def invalidate_benchmark(benchmark)
      Rails.cache.delete(benchmark: benchmark.id, relation: 'rules')
      Rails.cache.delete(benchmark: benchmark.id, relation: 'canonical_profiles')
    end
  end
end
