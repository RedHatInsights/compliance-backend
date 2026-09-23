# frozen_string_literal: true

# JSON serialization for Systems
class SystemSerializer < ApplicationSerializer
  attributes :display_name, :groups, :stale_timestamp, :updated, :insights_id, :tags,
             :os_major_version, :os_minor_version

  derived_attribute :culled_timestamp, :stale_timestamp
  derived_attribute :last_check_in, :stale_timestamp
  derived_attribute :stale_warning_timestamp, :stale_timestamp

  aggregated_attribute :policies, :policies, -> { System::POLICIES }
end
