# frozen_string_literal: true

# JSON API serialization for Hosts
class HostSerializer < ApplicationSerializer
  set_type :host
  attributes :name, :os_major_version, :os_minor_version, :last_scanned,
             :rules_passed, :rules_failed, :has_policy, :culled_timestamp,
             :stale_timestamp, :stale_warning_timestamp, :updated, :insights_id

  attribute :compliant do |host|
    host.compliant.values.all?
  end

  attribute :culled_timestamp do |host|
    host.culled_timestamp.iso8601
  end

  attribute :stale_timestamp do |host|
    host.stale_timestamp.iso8601
  end

  attribute :stale_warning_timestamp do |host|
    host.stale_warning_timestamp.iso8601
  end

  attribute :updated do |host|
    host.updated.iso8601
  end

  has_many :test_results

  # rubocop:disable Style/SymbolProc
  has_many :profiles do |host|
    host.all_profiles
  end
  # rubocop:enable Style/SymbolProc
end
