# frozen_string_literal: true

FactoryBot.define do
  factory :v2_rule_group_relationship, class: 'V2::RuleGroupRelationship' do
    for_rule_and_rule_requires

    trait :for_rule_group_and_rule_group_requires do
      association :left, factory: :v2_rule_group
      association :right, factory: :v2_rule_group
      relationship { 'requires' }
    end

    trait :for_rule_and_rule_requires do
      association :left, factory: :v2_rule
      association :right, factory: :v2_rule
      relationship { 'requires' }
    end

    trait :for_rule_and_rule_group_requires do
      association :left, factory: :v2_rule
      association :right, factory: :v2_rule_group
      relationship { 'requires' }
    end

    trait :for_rule_group_and_rule_requires do
      association :left, factory: :v2_rule_group
      association :right, factory: :v2_rule
      relationship { 'requires' }
    end

    trait :for_rule_group_and_rule_group_conflicts do
      association :left, factory: :v2_rule_group
      association :right, factory: :v2_rule_group
      relationship { 'conflicts' }
    end

    trait :for_rule_and_rule_conflicts do
      association :left, factory: :v2_rule
      association :right, factory: :v2_rule
      relationship { 'conflicts' }
    end

    trait :for_rule_and_rule_group_conflicts do
      association :left, factory: :v2_rule
      association :right, factory: :v2_rule_group
      relationship { 'conflicts' }
    end

    trait :for_rule_group_and_rule_conflicts do
      association :left, factory: :v2_rule_group
      association :right, factory: :v2_rule
      relationship { 'conflicts' }
    end
  end
end
