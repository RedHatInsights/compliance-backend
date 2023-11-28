# frozen_string_literal: true

FactoryBot.define do
  factory :profile_os_minor_version, class: 'V2::ProfileOsMinorVersion' do
    profile { association :v2_profile, os_major_version: os_major_version }
    os_minor_version { Faker::Number.between(from: 0, to: 9) }

    transient do
      os_major_version { 7 }
    end
  end
end
