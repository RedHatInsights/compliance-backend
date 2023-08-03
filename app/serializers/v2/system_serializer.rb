# frozen_string_literal: true

module V2
  # JSON API serialization for Systems
  class SystemSerializer < ApplicationSerializer
    set_type :system
    attributes :name, :groups, :os_major_version, :os_minor_version, :last_scanned,
               :rules_passed, :rules_failed, :has_policy, :culled_timestamp,
               :stale_timestamp, :stale_warning_timestamp, :updated, :insights_id,
               :compliant

    attribute :compliant do |system|
      system.compliant.values.all?
    end

    attribute :culled_timestamp do |system|
      system.culled_timestamp.iso8601
    end

    attribute :stale_timestamp do |system|
      system.stale_timestamp.iso8601
    end

    attribute :stale_warning_timestamp do |system|
      system.stale_warning_timestamp.iso8601
    end
  end
end
