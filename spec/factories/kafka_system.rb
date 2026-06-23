# frozen_string_literal: true

FactoryBot.define do
  factory :kafka_system, parent: :system, class: 'KafkaSystem' do
    # Override account association since KafkaSystem uses a string account, not a relation
    account { Faker::Number.number(digits: 5).to_s }
    org_id { Faker::Number.number(digits: 6).to_s }

    # Disable the after(:create) callbacks from the parent :system factory
    # because KafkaSystem does not have policy_systems or test_results associations
    after(:create) { |sys, ev| }
  end
end
