# frozen_string_literal: true

# JSON serialization for Systems
class SystemSerializer < ApplicationSerializer
  attributes :display_name, :groups, :stale_timestamp, :updated, :insights_id, :tags

  derived_attribute :culled_timestamp, :stale_timestamp
  derived_attribute :last_check_in, :stale_timestamp
  derived_attribute :stale_warning_timestamp, :stale_timestamp

  derived_attribute :os_major_version, System.os_major_version
  derived_attribute :os_minor_version, System.os_minor_version

  aggregated_attribute :policies, :policies, -> { System::POLICIES }
end
