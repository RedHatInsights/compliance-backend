# frozen_string_literal: true

FactoryBot.define do
  factory :v2_rule, class: 'V2::Rule' do
    ref_id { "foo_value_#{SecureRandom.uuid}" }
    title { Faker::Lorem.sentence }
    rationale { Faker::Lorem.paragraph }
    description { Faker::Lorem.paragraph }
    severity { %w[low medium high].sample }
    precedence { Faker::Number.between(from: 1, to: 9999) }

    security_guide { association :v2_security_guide, os_major_version: os_major_version }

    transient do
      os_major_version { 7 }
      profile_id { nil }
    end

    after(:create) do |rule, ev|
      next if ev.profile_id.nil?

      rule.profile_rules << FactoryBot.create(:v2_profile_rule, rule_id: rule.id, profile_id: ev.profile_id)
    end
  end
end
