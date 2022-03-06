# frozen_string_literal: true

FactoryBot.define do
  factory :test_result do
    host { association :host }
    profile { association :profile, :with_rules }
    end_time { Time.zone.now }
    score { SecureRandom.rand(98) + 1 }
  end
end
