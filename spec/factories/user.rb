# frozen_string_literal: true

FactoryBot.define do
  factory :v2_user, class: 'User' do
    sequence(:username) { |n| "testuser_#{n}@redhat.com" }
    account { association :v2_account }
  end
end
