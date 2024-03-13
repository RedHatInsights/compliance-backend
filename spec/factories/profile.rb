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
      rule_count { 0 }
    end

    os_minor_versions do
      supports_minors&.map do |os_minor_version|
        association(:profile_os_minor_version, os_minor_version: os_minor_version)
      end
    end

    value_overrides do
      create_list(:v2_value_definition, value_count, security_guide: security_guide) if value_count.positive?
      security_guide.value_definitions.each_with_object({}) do |value, object|
        object[value.ref_id] = SecureRandom.random_number(10)
      end
    end

    after(:create) do |profile, ev|
      next if ev.rule_count.zero?

      create_list(:v2_rule, ev.rule_count, profiles: [profile], security_guide: profile.security_guide)
    end
  end
end
