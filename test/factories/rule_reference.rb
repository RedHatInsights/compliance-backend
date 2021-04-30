# frozen_string_literal: true

FactoryBot.define do
  factory :rule_reference do
    href { Faker::Internet.url }
    label { Faker::Lorem.sentence }
  end
end
