# frozen_string_literal: true

FactoryBot.define do
  factory :system, class: 'V2::System' do
    id { Faker::Internet.uuid }
    account { association(:v2_account) }
    display_name { Faker::Internet.domain_name }
    stale_timestamp { 10.years.since(Time.zone.now) }
    updated { Time.zone.now }
    created { Time.zone.now }

    tags do
      tag_count.times.map do
        { namespace: Faker::Hacker.ingverb, key: Faker::Hacker.noun, value: Faker::Hacker.adjective }
      end
    end

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
      os_major_version { policy_id ? V2::Policy.find(policy_id).os_major_version : 8 }
      os_minor_version { 0 }
      group_count { 0 }
      tag_count { 5 }
      policy_id { nil }
    end

    after(:create) do |sys, ev|
      next if ev.policy_id.nil?

      sys.policy_systems << FactoryBot.create(:v2_policy_system, system_id: sys.id, policy_id: ev.policy_id)
    end
  end
end
