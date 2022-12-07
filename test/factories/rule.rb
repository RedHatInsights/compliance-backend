# frozen_string_literal: true

FactoryBot.define do
  factory :rule do
    title { Faker::Lorem.sentence }
    ref_id { "foo_rule_#{SecureRandom.uuid}" }
    description { Faker::Lorem.paragraph }
    rationale { Faker::Lorem.paragraph }
    severity { %w[low medium high].sample }
    slug { ref_id.parameterize }
    rule_group { association :rule_group, benchmark: benchmark }
    identifier { { system: Faker::Internet.url, label: Faker::Lorem.sentence } }
    benchmark

    trait :with_references do
      transient do
        reference_count { 3 }
      end

      after(:create) do |rule, evaluator|
        FactoryBot.create_list(:rule_reference, evaluator.reference_count, rules: [rule])
      end
    end
  end
end
