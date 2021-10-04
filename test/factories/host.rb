# frozen_string_literal: true

FactoryBot.define do
  # This is necessary to convince spring that the class is not defined elsewhere
  Object.send(:remove_const, :WHost) if defined?(WHost)
  Object.send(:remove_const, :SSGS) if defined?(SSGS)

  SSGS = SupportedSsg.all

  # A writable version of the Host model for the factory only
  class WHost < Host
    if Rails.env.test?
      self.table_name = 'inventory.hosts_v1_1'
    elsif Rails.env.development?
      self.table_name = 'hosts'

      establish_connection(
        Rails.configuration.database_configuration[Rails.env].merge(
          'database' => 'insights'
        )
      )
    end

    def readonly?
      false
    end
  end

  sequence(:account_number) { |n| format('%05<num>d', num: n) }

  factory :host, class: WHost do
    id { SecureRandom.uuid }
    account do
      User.current&.account&.account_number || generate(:account_number)
    end
    display_name { Faker::Internet.domain_name }
    tags { {} }
    stale_timestamp { 10.years.since(Time.zone.now) }
    if Rails.env.test?
      created { Time.zone.now }
      updated { Time.zone.now }
      system_profile do
        system_profile_data
      end
    elsif Rails.env.development?
      reporter { 'puptoo' }
      modified_on { Time.zone.now }
      facts { {} }
      canonical_facts do
        {
          'fqdn' => Faker::Internet.domain_name,
          'insights_id' => UUID.generate
        }
      end

      system_profile_facts do
        system_profile_data
      end
    end

    trait :random_os_version do
      transient do
        os_version_arr do
          ssg = SSGS.sample
          [ssg.os_major_version, ssg.os_minor_version]
        end
      end
    end

    transient do
      os_version_arr { [7, 9] }
      os_version { os_version_arr.join('.') }
      os_major_version { os_version_arr[0].to_i }
      os_minor_version { os_version_arr[1].to_i }

      system_profile_data do
        {
          'os_release' => os_version,
          'operating_system' => {
            'name' => 'RHEL',
            'major' => os_major_version,
            'minor' => os_minor_version
          }
        }
      end
    end
  end
end
