# frozen_string_literal: true

FactoryBot.define do
  factory :v2_rule, class: 'V2::Rule' do
    ref_id { "xccdf_org.ssgproject.content_rule_#{SecureRandom.hex}" }
    title { Faker::Lorem.sentence }
    rationale { Faker::Lorem.paragraph }
    description { Faker::Lorem.paragraph }
    severity { %w[low medium high].sample }
    precedence { Faker::Number.between(from: 1, to: 9999) }

    security_guide do
      if profile_id
        V2::Profile.find(profile_id).security_guide
      else
        association :v2_security_guide, os_major_version: os_major_version
      end
    end

    rule_group { association :v2_rule_group, parent_count: parent_count, security_guide: security_guide }

    transient do
      os_major_version { 7 }
      profile_id { nil }
      parent_count { (1..5).to_a.sample }
    end

    after(:create) do |rule, ev|
      next if ev.profile_id.nil?

      rule.profile_rules << FactoryBot.create(:v2_profile_rule, rule_id: rule.id, profile_id: ev.profile_id)
    end
  end
end
