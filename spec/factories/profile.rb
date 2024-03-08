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
      value_count { 0 }
    end

    os_minor_versions do
      supports_minors&.map do |os_minor_version|
        association(:profile_os_minor_version, os_minor_version: os_minor_version)
      end
    end

    trait :with_rules do
      after(:create) do |profile, _|
        create_list(
          :v2_rule,
          5,
          profiles: [profile],
          security_guide: profile.security_guide
        )
      end
    end

    value_overrides do
      if value_count > 0
        create_list(
          :v2_value_definition,
          value_count,
          security_guide: security_guide
        )
        security_guide.value_definitions.sample(value_count / 2).each_with_object({}) do |value, object|
          object[value.ref_id] = SecureRandom.random_number(10)
        end
      else
        {}
      end
    end
  end
end
