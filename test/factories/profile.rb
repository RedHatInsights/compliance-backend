# frozen_string_literal: true

FactoryBot.define do
  factory :profile do
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "xccdf_org.ssgproject.content_profile_#{SecureRandom.uuid}" }
    benchmark { association :benchmark, os_major_version: os_major_version }
    parent_profile do
      association(
        :canonical_profile,
        benchmark: benchmark,
        ref_id: ref_id,
        os_major_version: os_major_version,
        upstream: upstream
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
        rules = create_list(
          :rule,
          evaluator.rule_count,
          :with_references,
          profiles: [profile, profile&.parent_profile].compact,
          benchmark: profile.benchmark
        )

        rules.each do |rule|
          rule.rule_group.update(profiles: [profile, profile&.parent_profile].compact)
        end
      end
    end
  end
end
