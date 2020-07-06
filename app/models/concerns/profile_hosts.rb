# frozen_string_literal: true

# Methods that are related to a profile's hosts
module ProfileHosts
  extend ActiveSupport::Concern

  included do
    has_many :profile_hosts, dependent: :destroy
    has_many :hosts, through: :profile_hosts, source: :host

    def update_hosts(new_host_ids)
      return unless new_host_ids

      profile_hosts.where.not(host_id: new_host_ids).destroy_all
      ProfileHost.import((new_host_ids - host_ids).map do |host_id|
        { host_id: host_id, profile_id: id }
      end)
    end
  end
end
