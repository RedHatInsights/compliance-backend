# frozen_string_literal: true

FactoryBot.define do
  factory :v2_account, class: 'Account' do
    sequence(:org_id) { |n| format('%05<num>d', num: n) }
    identity_header do
      Insights::Api::Common::IdentityHeader.new(
        Base64.encode64({
          identity: {
            org_id: org_id,
            type: 'User',
            auth_type: auth_type,
            system: system_owner_id ? { cn: system_owner_id } : nil
          }.compact,
          entitlements: {
            insights: {
              is_entitled: true
            }
          }
        }.to_json)
      )
    end

    transient do
      auth_type { nil }
      system_owner_id { nil }
    end

    trait :with_cert_auth do
      transient do
        auth_type { Insights::Api::Common::IdentityHeader::CERT_AUTH }
        system_owner_id { Faker::Internet.uuid }
      end
    end

    trait :with_invalid_identity_type do
      identity_header do
        Insights::Api::Common::IdentityHeader.new(
          Base64.encode64({
            identity: {
              org_id: org_id,
              type: 'InvalidType'
            }.compact,
            entitlements: {
              insights: {
                is_entitled: true
              }
            }
          }.to_json)
        )
      end
    end

    trait :with_service_account_type do
      identity_header do
        Insights::Api::Common::IdentityHeader.new(
          Base64.encode64({
            identity: {
              org_id: org_id,
              type: 'ServiceAccount'
            }.compact,
            entitlements: {
              insights: {
                is_entitled: true
              }
            }
          }.to_json)
        )
      end
    end
  end
end
