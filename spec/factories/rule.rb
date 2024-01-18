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

    transient do
      os_major_version { 7 }
      profile_id { nil }
    end

    trait :with_group do
      rule_group { association :v2_rule_group, security_guide: security_guide }
    end

    trait :with_group_hierarchy do
      rule_group do
        association :v2_rule_group, parent_count: (1..5).to_a.sample, security_guide: security_guide
      end
    end

    after(:create) do |rule, ev|
      next if ev.profile_id.nil?

      rule.profile_rules << FactoryBot.create(:v2_profile_rule, rule_id: rule.id, profile_id: ev.profile_id)
    end
  end
end
