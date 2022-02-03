# frozen_string_literal: true

FactoryBot.define do
  factory :rule_group_relationship do
    for_rule_group_and_rule_group_requires
    trait :for_rule_group_and_rule_group_requires do
      association :left, factory: :rule_group
      association :right, factory: :rule_group
      relationship { 'requires' }
    end

    trait :for_rule_and_rule_requires do
      association :left, factory: :rule
      association :right, factory: :rule
      relationship { 'requires' }
    end

    trait :for_rule_and_rule_group_requires do
      association :left, factory: :rule
      association :right, factory: :rule_group
      relationship { 'requires' }
    end

    trait :for_rule_group_and_rule_requires do
      association :left, factory: :rule_group
      association :right, factory: :rule
      relationship { 'requires' }
    end

    trait :for_rule_group_and_rule_group_conflicts do
      association :left, factory: :rule_group
      association :right, factory: :rule_group
      relationship { 'conflicts' }
    end

    trait :for_rule_and_rule_conflicts do
      association :left, factory: :rule
      association :right, factory: :rule
      relationship { 'conflicts' }
    end

    trait :for_rule_and_rule_group_conflicts do
      association :left, factory: :rule
      association :right, factory: :rule_group
      relationship { 'conflicts' }
    end

    trait :for_rule_group_and_rule_conflicts do
      association :left, factory: :rule_group
      association :right, factory: :rule
      relationship { 'conflicts' }
    end
  end
end
