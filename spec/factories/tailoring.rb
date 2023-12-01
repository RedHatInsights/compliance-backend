# frozen_string_literal: true

FactoryBot.define do
  factory :v2_tailoring, class: 'V2::Tailoring' do
    profile { association :v2_profile, os_major_version: os_major_version }
    policy { association :v2_policy }
    os_minor_version { Faker::Number.between(from: 0, to: 100) }

    transient do
      value_overrides { {} }
      os_major_version { 7 }
    end

    after(:create, &:reload) # FIXME: remove this after the full remodel
  end
end
