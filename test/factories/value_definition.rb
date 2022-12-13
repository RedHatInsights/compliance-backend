# frozen_string_literal: true

FactoryBot.define do
  factory :value_definition do
    title { Faker::Lorem.sentence }
    value_type { 'boolean' }
    ref_id { "foo_rule_group_#{SecureRandom.uuid}" }
    description { Faker::Lorem.paragraph }
    benchmark
  end
end
