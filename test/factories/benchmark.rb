# frozen_string_literal: true

FactoryBot.define do
  factory :benchmark, class: Xccdf::Benchmark do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "xccdf_org.ssgproject.content_benchmark_RHEL-#{os_major_version}" }
    sequence(:version) { |n| "100.#{(n / 50).floor}.#{n % 50}" }

    transient do
      os_major_version { '7' }
    end

    trait :with_rules do
      transient do
        rule_count { 5 }
      end

      after(:create) do |benchmark, evaluator|
        create_list(
          :rule,
          evaluator.rule_count,
          benchmark: benchmark
        )
      end
    end

    trait :with_rule_groups do
      transient do
        rule_group_count { 5 }
      end

      after(:create) do |benchmark, evaluator|
        create_list(
          :rule_group,
          evaluator.rule_group_count,
          benchmark: benchmark
        )
      end
    end
  end
end
