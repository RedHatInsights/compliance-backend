# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class InventoryEventsConsumer < ApplicationConsumer
  NON_INSIGHTS_ID = '00000000-0000-0000-0000-000000000000'
  MAX_RETRIES = 3
  IMPORT_PAYLOAD_FIELDS = {
    'type' => nil,
    'id' => nil,
    'host' => {
      'id' => nil,
      'insights_id' => nil,
      'account' => nil,
      'org_id' => nil,
      'display_name' => nil,
      'groups' => nil,
      'tags' => nil,
      'stale_timestamp' => nil,
      'created' => nil,
      'updated' => nil,
      'system_profile' => {
        'owner_id' => nil,
        'operating_system' => {
          'major' => nil,
          'minor' => nil
        },
        'image_builder' => { 'compliance_policy_id' => nil }
      }
    },
    'platform_metadata' => {
      'service' => nil,
      'request_id' => nil,
      'org_id' => nil,
      'b64_identity' => nil,
      'url' => nil,
      'metadata' => nil
    }
  }.freeze

  def consume_one
    case message_type
    when 'delete'
      SystemDeleteJob.perform_later(delete_payload)
    when 'created', 'updated'
      SystemImportJob.perform_later(import_payload) if importable_host?(payload)
    else
      handle_other
    end
  end

  private

  def handle_other
    if service == 'compliance'
      Kafka::ReportParser.new(payload, logger).parse_reports
    else
      logger.debug "Skipped message of type '#{message_type}'"
    end
  end

  def payload
    return @payload if @payload_message.equal?(@message)

    @payload_message = @message
    @payload = JSON.parse(@message.raw_payload)
  end

  def import_payload
    project(payload, IMPORT_PAYLOAD_FIELDS)
  end

  def delete_payload
    payload.slice('id', 'org_id', 'updated', 'timestamp')
  end

  def project(value, fields)
    fields.each_with_object({}) do |(key, nested_fields), projected|
      if nested_fields
        projected[key] = project(value[key], nested_fields) if value[key]
      elsif value.key?(key)
        projected[key] = value[key]
      end
    end
  end

  def importable_host?(message)
    insights_id = message.dig('host', 'insights_id')
    insights_id.present? && insights_id != NON_INSIGHTS_ID && !excluded_host_type?(message)
  end

  def excluded_host_type?(message)
    profile = message.dig('host', 'system_profile') || {}

    profile['host_type'] == 'edge' ||
      profile.dig('operating_system', 'name')&.match?(/centos/i) ||
      profile.dig('bootc_status', 'booted', 'image_digest').present?
  end

  def service
    payload.dig('platform_metadata', 'service')
  end

  def message_type
    payload.dig('type')
  end
end
