# frozen_string_literal: true

FactoryBot.define do
  factory :policy do
    name { Faker::Lorem.sentence }
    account { User.current.account }
    compliance_threshold { Policy::DEFAULT_COMPLIANCE_THRESHOLD }
    profile_id { association(:canonical_profile).id }
  end
end
