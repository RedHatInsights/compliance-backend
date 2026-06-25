# frozen_string_literal: true

FactoryBot.define do
  factory :kafka_system, class: 'KafkaSystem' do
    id { Faker::Internet.uuid }
    account { Faker::Number.number(digits: 5).to_s }
    org_id { Faker::Number.number(digits: 6).to_s }
    display_name { Faker::Internet.domain_name }
    stale_timestamp { 10.years.since(Time.zone.now) }
    updated { Time.zone.now }
    created { Time.zone.now }
    tags { [] }
    groups { [] }
    system_profile { {} }
  end
end
