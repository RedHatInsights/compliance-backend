# frozen_string_literal: true

FactoryBot.define do
  factory :rule_group do
    title { Faker::Lorem.sentence }
    ref_id { "foo-#{SecureRandom.uuid}" }
    description { Faker::Lorem.paragraph }
    rationale { Faker::Lorem.paragraph }
    benchmark
  end
end
