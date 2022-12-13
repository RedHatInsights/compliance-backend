# frozen_string_literal: true

FactoryBot.define do
  factory :rule_references_container do
    transient do
      reference_count { 3 }
    end

    rule_references do
      reference_count.times.map do
        {
          href: Faker::Internet.url,
          label: Faker::Lorem.sentence
        }
      end
    end
  end
end
