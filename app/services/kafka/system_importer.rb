# frozen_string_literal: true

module Kafka
  # Imports host events from Inventory into the systems table
  class SystemImporter
    OWNER_ID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

    def initialize(message, logger = Rails.logger)
      @message = message
      @logger = logger
    end

    def import
      payload = @message.dig('host')
      return unless payload_valid_for_import?(payload)

      id, updated = payload.values_at('id', 'updated')

      upsert_system(id, payload, updated)
    rescue StandardError => e
      failed_id = id || payload&.dig('id') || 'unknown'
      @logger.audit_fail("[Kafka::SystemImporter] Failed to import system #{failed_id}: #{e.message}")
      raise e
    end

    private

    def payload_valid_for_import?(payload)
      unless valid_payload?(payload)
        @logger.error('[Kafka::SystemImporter] Ignored invalid message: missing host id or malformed tags')
        Yabeda.compliance_system_import_invalid_total.increment({})
        return false
      end
      true
    end

    def extract_system_attrs(id, payload, updated)
      system_profile = relevant_system_profile(payload)
      {
        id: id, account: payload.dig('account'), org_id: payload.dig('org_id'),
        display_name: payload.dig('display_name'), groups: payload.dig('groups') || [],
        tags: payload.dig('tags') || [], system_profile: system_profile,
        stale_timestamp: payload.dig('stale_timestamp'), created: payload.dig('created'),
        updated: updated, insights_id: payload.dig('insights_id'),
        deleted_at: nil
      }.merge(native_system_profile_attrs(system_profile))
    end

    def native_system_profile_attrs(system_profile)
      operating_system = system_profile['operating_system']
      operating_system = {} unless operating_system.is_a?(Hash)
      {
        os_major_version: operating_system['major'],
        os_minor_version: operating_system['minor'],
        owner_id: native_owner_id(system_profile['owner_id'])
      }
    end

    def native_owner_id(owner_id)
      return owner_id if owner_id.nil? || (owner_id.is_a?(String) && OWNER_ID_FORMAT.match?(owner_id))

      @logger.error("[Kafka::SystemImporter] Malformed owner_id: #{owner_id.inspect}")
      nil
    end

    def relevant_system_profile(payload)
      full_profile = payload.dig('system_profile')
      return {} unless full_profile.is_a?(Hash)

      full_profile.slice('operating_system', 'owner_id')
    end

    # rubocop:disable Metrics/MethodLength
    def upsert_system(id, payload, updated)
      attrs = extract_system_attrs(id, payload, updated)
      # rubocop:disable Rails/SkipsModelValidations
      # rubocop:disable Layout/LineLength
      result = System.upsert(
        attrs,
        unique_by: :id,
        returning: %w[id],
        on_duplicate: Arel.sql('account = EXCLUDED.account, org_id = EXCLUDED.org_id, display_name = EXCLUDED.display_name, groups = EXCLUDED.groups, tags = EXCLUDED.tags, system_profile = EXCLUDED.system_profile, os_major_version = EXCLUDED.os_major_version, os_minor_version = EXCLUDED.os_minor_version, owner_id = EXCLUDED.owner_id, stale_timestamp = EXCLUDED.stale_timestamp, created = EXCLUDED.created, updated = EXCLUDED.updated, insights_id = EXCLUDED.insights_id, deleted_at = EXCLUDED.deleted_at WHERE COALESCE(systems.deleted_at, systems.updated) < EXCLUDED.updated')
      )
      # rubocop:enable Layout/LineLength
      # rubocop:enable Rails/SkipsModelValidations
      log_upsert_result(result, id)
    rescue ActiveRecord::ActiveRecordError
      Yabeda.compliance_system_import_failures_total.increment({})
      raise
    end
    # rubocop:enable Metrics/MethodLength

    def log_upsert_result(result, id)
      if result.rows.empty?
        @logger.info("[Kafka::SystemImporter] Ignored stale message for system #{id}")
        Yabeda.compliance_system_import_stale_total.increment({})
      else
        @logger.audit_success("[Kafka::SystemImporter] Imported system #{id}")
      end
    end

    def valid_payload?(payload)
      payload.present? &&
        payload.dig('id').present? &&
        valid_tags?(payload.dig('tags'))
    end

    def valid_tags?(tags)
      return true if tags.blank?

      tags.is_a?(Array) && tags.all?(Hash)
    end
  end
end
