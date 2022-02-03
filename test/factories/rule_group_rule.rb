# frozen_string_literal: true

FactoryBot.define do
  factory :rule_group_rule do
    association :rule_group, factory: :rule_group
    association :rule, factory: :rule
  end
end
