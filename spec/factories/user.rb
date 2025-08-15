# frozen_string_literal: true

FactoryBot.define do
  factory :v2_user, class: 'User' do
    sequence(:username) { |n| "testuser_#{n}@redhat.com" }
    account { association :v2_account }

    trait :with_cert_auth do
      transient { system_owner_id { Faker::Internet.uuid } }

      account { association :v2_account, :with_cert_auth, system_owner_id: system_owner_id }
    end

    trait :with_service_account_type do
      account { association :v2_account, :with_service_account_type }
    end

    trait :with_invalid_identity_type do
      account { association :v2_account, :with_invalid_identity_type }
    end
  end
end
