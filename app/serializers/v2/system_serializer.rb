# frozen_string_literal: true

module V2
  # JSON serialization for Systems
  class SystemSerializer < V2::ApplicationSerializer
    attributes :name, :os_major_version, :os_minor_version, :groups, :culled_timestamp,
               :stale_timestamp, :stale_warning_timestamp, :updated, :insights_id, :tags

    # derived_attribute :policies, policies: [:title]
  end
end
