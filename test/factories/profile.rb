# frozen_string_literal: true

FactoryBot.define do
  factory :profile do
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "foo-#{SecureRandom.uuid}" }
    benchmark { association :benchmark, os_major_version: os_major_version }
    parent_profile do
      association(
        :canonical_profile,
        benchmark: benchmark,
        ref_id: ref_id,
        os_major_version: os_major_version
      )
    end
    account { User.current&.account }
    policy do
      association :policy,
                  account: account,
                  name: name,
                  description: description
    end

    factory :canonical_profile do
      parent_profile { nil }
      account { nil }
      policy { nil }
    end

    transient do
      os_major_version { '7' }
    end

    trait :with_rules do
      transient do
        rule_count { 5 }
      end

      after(:create) do |profile, evaluator|
        create_list(
          :rule,
          evaluator.rule_count,
          profiles: [profile, profile&.parent_profile].compact,
          benchmark: profile.benchmark
        )
      end
    end
  end
end
