# frozen_string_literal: true

FactoryBot.define do
  factory :v2_rule, class: 'V2::Rule' do
    ref_id { "xccdf_org.ssgproject.content_rule_#{SecureRandom.hex}" }
    title { Faker::Lorem.sentence }
    rationale { Faker::Lorem.paragraph }
    description { Faker::Lorem.paragraph }
    severity { %w[low medium high].sample }
    precedence { Faker::Number.between(from: 1, to: 9999) }

    security_guide { association :v2_security_guide, os_major_version: os_major_version }
    profile_rules { [association(:v2_profile_rule, profile_id: profile_id)] unless profile_id.nil? }

    transient do
      os_major_version { 7 }
      profile_id { nil }
    end
  end
end
