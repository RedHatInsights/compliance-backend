# frozen_string_literal: true

# Imports a system and its associated compliance data
class SystemImportJob < ApplicationJob
  DATABASE_RETRY_HANDLER = [
    ActiveRecord::Deadlocked,
    ActiveRecord::ConnectionFailed,
    ActiveRecord::ConnectionNotEstablished,
    ActiveRecord::SerializationFailure
  ].to_s.freeze

  queue_as :imports

  include InventorySystemConcurrency

  def perform(message)
    @message = message
    import_system
    import_policy_system if policy_id
    Kafka::ReportParser.new(@message, Rails.logger).parse_reports if compliance?
  end

  private

  def import_system
    payload = @message.dig('host')
    return unless payload_valid_for_import?(payload)

    id, updated = payload.values_at('id', 'updated')

    upsert_system(id, payload, updated)
  rescue StandardError => e
    failed_id = id || payload&.dig('id') || 'unknown'
    Rails.logger.audit_fail("[SystemImportJob] Failed to import system #{failed_id}: #{e.message}")
    raise e
  end

  def payload_valid_for_import?(payload)
    unless valid_payload?(payload)
      Rails.logger.error('[SystemImportJob] Ignored invalid message: missing host id or malformed tags')
      Yabeda.compliance_system_import_invalid_total.increment({})
      return false
    end

    true
  end

  def extract_system_attrs(id, payload, updated)
    native_fields = SystemProfileNativeFields.normalize(payload['system_profile'])
    log_malformed_owner if native_fields.malformed_owner_id?
    {
      id: id, account: payload.dig('account'), org_id: payload.dig('org_id'),
      display_name: payload.dig('display_name'), groups: payload.dig('groups') || [],
      tags: payload.dig('tags') || [], stale_timestamp: payload.dig('stale_timestamp'),
      created: payload.dig('created'), updated: updated,
      insights_id: payload.dig('insights_id'), deleted_at: nil
    }.merge(native_fields.native_attributes)
  end

  def log_malformed_owner
    Rails.logger.error('[SystemImportJob] Malformed owner_id')
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
      on_duplicate: Arel.sql('account = EXCLUDED.account, org_id = EXCLUDED.org_id, display_name = EXCLUDED.display_name, groups = EXCLUDED.groups, tags = EXCLUDED.tags, os_major_version = EXCLUDED.os_major_version, os_minor_version = EXCLUDED.os_minor_version, owner_id = EXCLUDED.owner_id, stale_timestamp = EXCLUDED.stale_timestamp, created = EXCLUDED.created, updated = EXCLUDED.updated, insights_id = EXCLUDED.insights_id, deleted_at = EXCLUDED.deleted_at WHERE COALESCE(systems.deleted_at, systems.updated) < EXCLUDED.updated')
    )
    # rubocop:enable Layout/LineLength
    # rubocop:enable Rails/SkipsModelValidations
    log_upsert_result(result, id)
  rescue ActiveRecord::ActiveRecordError
    Yabeda.compliance_system_import_failures_total.increment({}) if terminal_import_attempt?
    raise
  end
  # rubocop:enable Metrics/MethodLength

  def log_upsert_result(result, id)
    if result.rows.empty?
      Rails.logger.info("[SystemImportJob] Ignored stale message for system #{id}")
      Yabeda.compliance_system_import_stale_total.increment({})
    else
      Rails.logger.audit_success("[SystemImportJob] Imported system #{id}")
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

  # rubocop:disable Metrics/MethodLength
  def import_policy_system
    @policy_id = @message.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
    @system_id = @message.dig('host', 'id')
    @org_id = @message.dig('host', 'org_id')
    @msg_type = @message.dig('type')
    @request_id = @message.dig('platform_metadata', 'request_id')
    return unless sources_exist?

    policy_system = PolicySystem.new(policy_id: @policy_id, system_id: @system_id, request_id: @request_id)
    if policy_system.save
      Rails.logger.audit_success(
        "[#{@org_id}] Imported PolicySystem for System #{@system_id} from #{@msg_type} message"
      )
    else
      audit_policy_system_failure(policy_system.errors.full_messages.join(', ').to_s)
    end
  end
  # rubocop:enable Metrics/MethodLength

  def sources_exist?
    valid_resource_exists?(System, @system_id, 'System', raise_on_missing: true) &&
      valid_resource_exists?(Policy, @policy_id, 'Policy')
  end

  def valid_resource_exists?(model_class, id, resource_name, raise_on_missing: false)
    return true if model_class.exists?(id: id)

    audit_policy_system_failure("#{resource_name} not found with ID #{id}")
    raise ActiveRecord::RecordNotFound if raise_on_missing

    false
  end

  def audit_policy_system_failure(message)
    Rails.logger.audit_fail("[#{@org_id}] Failed to import PolicySystem: #{message}")
  end

  def terminal_import_attempt?
    (exception_executions || {}).fetch(DATABASE_RETRY_HANDLER, 0) >= 2
  end

  def policy_id
    @message.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
  end

  def compliance?
    @message.dig('platform_metadata', 'service') == 'compliance'
  end
end
