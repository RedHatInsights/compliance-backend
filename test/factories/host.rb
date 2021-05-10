# frozen_string_literal: true

FactoryBot.define do
  # This is necessary to convince spring that the class is not defined elsewhere
  Object.send(:remove_const, :WHost) if defined?(WHost)

  # A writable version of the Host model for the factory only
  class WHost < Host
    self.table_name = 'inventory.hosts_v1_1'

    def readonly?
      false
    end
  end

  factory :host, class: WHost do
    id { SecureRandom.uuid }
    account { User.current&.account&.account_number }
    display_name { Faker::Lorem.sentence }
    tags { {} }
    created { Time.zone.now }
    updated { Time.zone.now }
    stale_timestamp { 10.years.since(Time.zone.now) }
    system_profile do
      {
        'operating_system' => {
          'major' => os_major_version,
          'minor' => os_minor_version
        }
      }
    end

    transient do
      os_major_version { 7 }
      os_minor_version { 9 }
    end
  end
end
