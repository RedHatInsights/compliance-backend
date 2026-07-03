# frozen_string_literal: true

FactoryBot.define do
  factory :value_definition, class: 'ValueDefinition' do
    ref_id { "foo_value_#{SecureRandom.uuid}" }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    value_type { 'number' }
    default_value { SecureRandom.random_number.to_s }

    security_guide { association :security_guide, os_major_version: os_major_version }

    transient do
      os_major_version { 7 }
    end
  end
end
