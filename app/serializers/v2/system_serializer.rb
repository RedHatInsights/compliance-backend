# frozen_string_literal: true

module V2
  # JSON serialization for Systems
  class SystemSerializer < V2::ApplicationSerializer
    attributes :display_name, :groups, :culled_timestamp,
               :stale_timestamp, :stale_warning_timestamp, :updated, :insights_id, :tags

    derived_attribute :last_check_in, V2::System.last_check_in
    derived_attribute :os_major_version, V2::System.os_major_version
    derived_attribute :os_minor_version, V2::System.os_minor_version

    aggregated_attribute :policies, :policies, -> { V2::System::POLICIES }
  end
end
