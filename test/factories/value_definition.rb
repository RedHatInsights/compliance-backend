# frozen_string_literal: true

FactoryBot.define do
  factory :value_definition do
    title { Faker::Lorem.sentence }
    value_type { 'boolean' }
    ref_id { "foo_value_#{SecureRandom.uuid}" }
    description { Faker::Lorem.paragraph }
    benchmark
    default_value { 'true' }
  end
end
