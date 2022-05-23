# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:account_number) { |n| format('%05<num>d', num: n) }
    sequence(:org_id) { |n| format('%05<num>d', num: n) }
    identity_header do
      IdentityHeader.new(
        Base64.encode64({
          identity: {
            account_number: account_number,
            org_id: org_id
          }
        }.to_json)
      )
    end
  end
end
