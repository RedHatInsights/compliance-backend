# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "testuser_#{n}@redhat.com" }
    account
  end
end
