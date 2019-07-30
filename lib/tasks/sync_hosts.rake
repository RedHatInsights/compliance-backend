# frozen_string_literal: true

namespace :sync do
  desc <<~END_DESC
    Mark iterates through all hosts and marks the last time we've seen them on the inventory.
    If a host isn't seen in the inventory we will mark it as disabled, so it will not show up
    in the inventory. This is a safeguard in case the Inventory API is down or returns wrong data
    for any reason.
  END_DESC
  task mark: :environment do
    HostsSync.mark_last_seen
  end

  desc <<~END_DESC
    Sweep finds all of the hosts marked as "disabled" for longer than a week, and removes all of its
    related data from the database.
  END_DESC
  task sweep: :environment do
    HostsSync.remove_disabled_hosts
  end
end
