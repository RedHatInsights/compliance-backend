# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:org_id) { |n| format('%05<num>d', num: n) }
    identity_header do
      Insights::Api::Common::IdentityHeader.new(
        Base64.encode64({
          identity: {
            org_id: org_id
          }
        }.to_json)
      )
    end
  end
end
