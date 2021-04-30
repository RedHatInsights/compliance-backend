# frozen_string_literal: true

FactoryBot.define do
  factory :rule_identifier do
    system { Faker::Internet.url }
    label { Faker::Lorem.sentence }
  end
end
