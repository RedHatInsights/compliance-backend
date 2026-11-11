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
      'subscription_manager_id' => nil,
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

  def consume
    Rails.application.executor.wrap do
      log_metadata
      accepted, entries, error = accept_messages
      deliver(accepted, entries)
      # Malformed messages are left unacknowledged so Karafka retries and routes them to the DLQ
      raise error if error
    end
  end

  private

  # Collects entries up to, and excluding, the first message that cannot be processed
  def accept_messages
    accepted = []
    entries = []
    messages.each do |message|
      entry = entry_for(message)
      entries << entry if entry
      accepted << message
    end
    [accepted, entries, nil]
  rescue StandardError => e
    [accepted, entries, e]
  end

  def deliver(accepted, entries)
    enqueue_batch(entries)
    accepted.each { |message| mark_as_consumed(message) }
  end

  def enqueue_batch(entries)
    return if entries.empty?

    enqueued = InventoryEventsBatchJob.perform_later(entries)
    raise ActiveJob::EnqueueError, 'Failed to enqueue inventory events batch' unless enqueued
  end

  def entry_for(message)
    event = payload(message)
    type = event['type']
    projected_payload = projected_payload_for(type, event)
    return unless projected_payload

    { 'type' => type, 'payload' => projected_payload, 'metadata' => kafka_metadata(message) }
  end

  def projected_payload_for(type, event)
    return delete_payload(event) if type == 'delete'

    if %w[created updated].include?(type)
      return import_payload(event) if importable_host?(event)

      logger.debug "Skipped ineligible host for event type '#{type}'"
      return
    end

    logger.debug "Skipped message of type '#{type}'"
    nil
  end

  def payload(message)
    JSON.parse(message.raw_payload)
  end

  def import_payload(event)
    project(event, IMPORT_PAYLOAD_FIELDS)
  end

  def project(value, fields)
    fields.each_with_object({}) do |(key, nested), result|
      if nested
        result[key] = project(value[key], nested) if value[key]
      elsif value.key?(key)
        result[key] = value[key]
      end
    end
  end

  def delete_payload(event)
    event.slice('id', 'org_id', 'updated', 'timestamp')
  end

  def kafka_metadata(message)
    {
      'topic' => message.topic,
      'partition' => message.partition,
      'offset' => message.offset,
      'timestamp' => message.timestamp
    }
  end

  def importable_host?(event)
    insights_id = event.dig('host', 'insights_id')
    insights_id.present? && insights_id != NON_INSIGHTS_ID && !excluded_host_type?(event)
  end

  def excluded_host_type?(event)
    profile = event.dig('host', 'system_profile') || {}
    profile['host_type'] == 'edge' || profile.dig('operating_system', 'name')&.match?(/centos/i) ||
      profile.dig('bootc_status', 'booted', 'image_digest').present?
  end
end
