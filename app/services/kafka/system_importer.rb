# frozen_string_literal: true

module Kafka
  # Imports host events from Inventory into the systems table
  class SystemImporter
    def initialize(message, logger = Rails.logger)
      @message = message
      @logger = logger
    end

    def import
      payload = @message.dig('host')
      return unless payload_valid_for_import?(payload)

      id, updated = payload.values_at('id', 'updated')

      return if existing_message_stale?(id, updated)

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
        return false
      end
      true
    end

    def existing_message_stale?(id, updated)
      existing = KafkaSystem.find_by(id: id)
      if existing && stale_message?(existing, updated)
        @logger.info("[Kafka::SystemImporter] Ignored stale message for system #{id}")
        return true
      end
      false
    end

    # rubocop:disable Metrics/MethodLength
    def system_attributes(id, payload, updated)
      {
        id: id,
        account: payload.dig('account'),
        org_id: payload.dig('org_id'),
        display_name: payload.dig('display_name'),
        groups: payload.dig('groups') || [],
        tags: payload.dig('tags') || [],
        system_profile: payload.dig('system_profile'),
        stale_timestamp: payload.dig('stale_timestamp'),
        created: payload.dig('created'),
        updated: updated,
        insights_id: payload.dig('insights_id')
      }
    end
    # rubocop:enable Metrics/MethodLength

    def upsert_system(id, payload, updated)
      attrs = system_attributes(id, payload, updated)

      # rubocop:disable Rails/SkipsModelValidations
      # rubocop:disable Layout/LineLength
      KafkaSystem.upsert(
        attrs,
        unique_by: :id,
        on_duplicate: Arel.sql('account = EXCLUDED.account, org_id = EXCLUDED.org_id, display_name = EXCLUDED.display_name, groups = EXCLUDED.groups, tags = EXCLUDED.tags, system_profile = EXCLUDED.system_profile, stale_timestamp = EXCLUDED.stale_timestamp, created = EXCLUDED.created, updated = EXCLUDED.updated, insights_id = EXCLUDED.insights_id WHERE systems.updated IS NULL OR systems.updated < EXCLUDED.updated')
      )
      # rubocop:enable Layout/LineLength
      # rubocop:enable Rails/SkipsModelValidations
      @logger.audit_success("[Kafka::SystemImporter] Imported system #{id}")
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

    def stale_message?(existing, updated)
      existing.updated.present? && updated.present? && existing.updated.to_time >= updated.to_time
    end
  end
end
