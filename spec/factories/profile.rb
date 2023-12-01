# frozen_string_literal: true

FactoryBot.define do
  factory :v2_profile, class: 'V2::Profile' do
    id { SecureRandom.uuid }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "xccdf_org.ssgproject.content_profile_#{ref_id_suffix}" }
    security_guide { association :v2_security_guide, os_major_version: os_major_version }
    upstream { false }

    transient do
      os_major_version { 7 }
      ref_id_suffix { SecureRandom.hex }
      supports_minors { [] }
    end

    os_minor_versions do
      supports_minors&.map do |os_minor_version|
        association(:profile_os_minor_version, os_minor_version: os_minor_version)
      end
    end

    trait :with_rules do
      transient do
        rule_count { 5 }
      end

      after(:create) do |profile, evaluator|
        create_list(
          :v2_rule,
          evaluator.rule_count,
          :with_group_hierarchy,
          profiles: [profile],
          security_guide: profile.security_guide
        )
      end
    end
  end
end
