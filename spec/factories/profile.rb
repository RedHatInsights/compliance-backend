# frozen_string_literal: true

FactoryBot.define do
  factory :v2_profile, class: 'V2::Profile' do
    id { SecureRandom.uuid }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "xccdf_org.ssgproject.content_profile_#{SecureRandom.uuid}" }
    security_guide { association :v2_security_guide, os_major_version: os_major_version }

    transient do
      os_major_version { 7 }
    end
  end
end
