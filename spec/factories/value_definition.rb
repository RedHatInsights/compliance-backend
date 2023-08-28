# frozen_string_literal: true

FactoryBot.define do
  factory :v2_value_definition, class: V2::ValueDefinition do
    ref_id { "foo_value_#{SecureRandom.uuid}" }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    value_type { 'boolean' }
    default_value { %w[true false].sample }

    security_guide { association :v2_security_guide, os_major_version: os_major_version }

    transient do
      os_major_version { 7 }
    end
  end
end
