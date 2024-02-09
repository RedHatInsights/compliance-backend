# frozen_string_literal: true

FactoryBot.define do
  factory :system, class: 'V2::System' do
    id { Faker::Internet.uuid }
    account { association(:v2_account) }
    display_name { Faker::Internet.domain_name }
    stale_timestamp { 10.years.since(Time.zone.now) }
    updated { Time.zone.now }
    created { Time.zone.now }
    tags { [] }

    groups do
      group_count.times.map do
        { id: Faker::Internet.uuid, name: Faker::Hacker.abbreviation }
      end
    end

    system_profile do
      {
        'os_release' => [os_major_version, os_minor_version].join('.'),
        'operating_system' => {
          'name' => 'RHEL',
          'major' => os_major_version,
          'minor' => os_minor_version
        }
      }
    end

    transient do
      os_major_version { 8 }
      os_minor_version { 0 }
      group_count { 0 }
    end
  end
end
