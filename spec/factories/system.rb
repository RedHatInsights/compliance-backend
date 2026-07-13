# frozen_string_literal: true

FactoryBot.define do
  factory :system, class: System do
    id { Faker::Internet.uuid }
    account { association(:account) }
    display_name { Faker::Internet.domain_name }
    stale_timestamp { 10.years.since(Time.zone.now) }
    created { Time.zone.now }
    updated { Time.zone.now }
    system_profile do
      {
        'os_release' => [os_major_version, os_minor_version].join('.'),
        'operating_system' => {
          'name' => 'RHEL',
          'major' => os_major_version,
          'minor' => os_minor_version
        },
        'owner_id' => owner_id
      }
    end
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

    # inventory.hosts is an auto-updatable view; inserts pass through to the
    # underlying table automatically. Reload after save to populate computed
    # view columns (culled_timestamp, stale_warning_timestamp, last_check_in).
    to_create do |instance|
      instance.save!
      instance.reload
    end

    transient do
      os_major_version { policy_id ? Policy.find(policy_id).os_major_version : 8 }
      os_minor_version { 0 }
      group_count { 0 }
      tag_count { 5 }
      policy_id { nil }
      owner_id { Faker::Internet.uuid }
      with_test_result { nil }
    end

    after(:create) do |sys, ev|
      next if ev.policy_id.nil?

      sys.policy_systems << FactoryBot.create(:policy_system, system_id: sys.id, policy_id: ev.policy_id)

      next if ev.with_test_result.nil?

      FactoryBot.create(:test_result, system: sys, report_id: ev.policy_id)
    end

    # Used only by dev-env DB seeders (db/seeds.dev.rb).
    # hbi.hosts lives in a separate database and is not auto-updatable from
    # the main connection, so we need a dedicated write proxy.
    trait :dev_seed do
      to_create do |instance|
        unless defined?(WSystem)
          Object.const_set(:WSystem, Class.new(System) do
            self.table_name = 'hbi.hosts'

            def readonly?
              false
            end
          end)
          WSystem.establish_connection(
            Rails.configuration.database_configuration[Rails.env].merge('database' => 'insights')
          )
        end

        unless defined?(WSystemProfileStatic)
          Object.const_set(:WSystemProfileStatic, Class.new(ApplicationRecord) do
            self.table_name = 'hbi.system_profiles_static'
            self.primary_key = %i[org_id host_id]

            def readonly?
              false
            end
          end)
          WSystemProfileStatic.establish_connection(
            Rails.configuration.database_configuration[Rails.env].merge('database' => 'insights')
          )
        end

        attrs = instance.attributes.slice(*WSystem.column_names)
        attrs['created_on'] ||= instance.attributes['created']
        attrs['modified_on'] ||= instance.attributes['updated']
        attrs['reporter'] ||= 'compliance'
        WSystem.create!(attrs.compact)

        sp = instance.system_profile || {}
        WSystemProfileStatic.create!(
          org_id: instance.org_id,
          host_id: instance.id,
          operating_system: sp['operating_system'] || {},
          owner_id: sp['owner_id'],
          host_type: nil
        )

        instance.reload
      end
    end
  end
end
