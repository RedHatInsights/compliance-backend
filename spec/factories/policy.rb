# frozen_string_literal: true

FactoryBot.define do
  factory :policy, class: 'Policy' do
    account { association :account }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    profile { association :profile, os_major_version: os_major_version, supports_minors: supports_minors }
    compliance_threshold { SecureRandom.random_number(100) }

    transient do
      os_major_version { 7 }
      system_id { nil }
      supports_minors { [] }
      system_count { 0 }
      empty_policy { false }
    end

    trait :for_tailoring do
      profile do
        association(
          :profile,
          os_major_version: os_major_version,
          supports_minors: supports_minors,
          value_count: 5,
          rule_count: 20
        )
      end
    end

    after(:create) do |policy, ev|
      if ev.system_id # If system_id is specified, do not generate any assigned systems
        policy.policy_systems << FactoryBot.create(:policy_system, system_id: ev.system_id, policy_id: policy.id)
      elsif ev.supports_minors.any? && !ev.empty_policy
        ev.system_count.times do
          FactoryBot.create(
            :system,
            os_major_version: ev.os_major_version,
            os_minor_version: ev.supports_minors.sample,
            account: policy.account,
            policy_id: policy.id
          )
        end
      end
    end
  end
end
