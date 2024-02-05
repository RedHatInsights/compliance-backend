# frozen_string_literal: true

FactoryBot.define do
  factory :v2_policy, class: 'V2::Policy' do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    profile { association :v2_profile, os_major_version: os_major_version }
    compliance_threshold { SecureRandom.random_number(100) }
    system_count { 0 }

    transient do
      os_major_version { 7 }
    end
  end
end
