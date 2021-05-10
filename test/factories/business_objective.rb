# frozen_string_literal: true

FactoryBot.define do
  factory :business_objective do
    title { Faker::Lorem.sentence }
  end
end
