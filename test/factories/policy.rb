# frozen_string_literal: true

FactoryBot.define do
  factory :policy do
    name { Faker::Lorem.sentence }
    account { User.current.account }
  end
end
