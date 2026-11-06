# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: 'User' do
    sequence(:username) { |n| "testuser_#{n}@redhat.com" }
    account { association :account }

    trait :with_cert_auth do
      transient do
        system_owner_id { Faker::Internet.uuid }
        cert_type { nil }
        identity_type { 'User' }
      end

      account do
        association :account, :with_cert_auth,
                    system_owner_id: system_owner_id,
                    cert_type: cert_type,
                    identity_type: identity_type
      end
    end

    trait :with_service_account_type do
      account { association :account, :with_service_account_type }
    end

    trait :with_invalid_identity_type do
      account { association :account, :with_invalid_identity_type }
    end
  end
end
