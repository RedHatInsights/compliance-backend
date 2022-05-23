# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:account_number) { |n| format('%05<num>d', num: n) }
    sequence(:org_id) { |n| format('%05<num>d', num: n) }
  end
end
