# frozen_string_literal: true

# Methods that are related to a profile's hosts
module ProfileHosts
  extend ActiveSupport::Concern

  included do
    has_many :profile_hosts, dependent: :destroy
    has_many :hosts, through: :profile_hosts, source: :host

    def update_hosts(ids)
      return unless ids

      profile_hosts.destroy_all

      new_profile_hosts = Host.find_or_create_hosts_by_inventory_ids(ids)
                              .map do |host|
        { host_id: host.id, profile_id: id }
      end
      ProfileHost.import!(new_profile_hosts)
    end
  end
end
