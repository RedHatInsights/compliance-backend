# frozen_string_literal: true

FactoryBot.define do
  factory :rule_result do
    host
    test_result { association :test_result, host: host }
    rule { test_result.profile.rules.sample }
    result { 'pass' }
  end
end
