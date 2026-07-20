# frozen_string_literal: true

# JSON serialization for Systems
class SystemSerializer < ApplicationSerializer
  attributes :display_name, :groups, :culled_timestamp, :last_check_in,
             :stale_timestamp, :stale_warning_timestamp, :updated, :insights_id, :tags

  derived_attribute :os_major_version, System.os_major_version
  derived_attribute :os_minor_version, System.os_minor_version

  aggregated_attribute :policies, :policies, -> { System::POLICIES }
end
