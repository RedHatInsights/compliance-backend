# frozen_string_literal: true

FactoryBot.define do
  factory :v2_policy, class: 'V2::Policy' do
    # account { association(:v2_account) }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    profile { association :v2_profile, os_major_version: os_major_version, supports_minors: supports_minors }
    compliance_threshold { SecureRandom.random_number(100) }

    transient do
      os_major_version { 7 }
      system_id { nil }
      supports_minors { [] }
    end

    after(:create) do |policy, ev|
      next if ev.system_id.nil?

      policy.policy_systems << FactoryBot.create(:v2_policy_system, system_id: ev.system_id, policy_id: policy.id)
    end
  end
end
