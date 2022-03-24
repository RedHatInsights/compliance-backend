# frozen_string_literal: true

FactoryBot.define do
  factory :rule do
    title { Faker::Lorem.sentence }
    ref_id { "foo_rule_#{SecureRandom.uuid}" }
    description { Faker::Lorem.paragraph }
    rationale { Faker::Lorem.paragraph }
    severity { %w[low medium high].sample }
    benchmark
  end
end
