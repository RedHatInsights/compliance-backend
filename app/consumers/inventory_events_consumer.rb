# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class InventoryEventsConsumer < ApplicationConsumer
  NON_INSIGHTS_ID = '00000000-0000-0000-0000-000000000000'
  MAX_RETRIES = 3

  def consume
    Rails.application.executor.wrap do
      log_metadata
      grouped_messages.each_value { |group| enqueue_group(group) }
    end
  end

  private

  def grouped_messages
    messages.each_with_object({}) do |kafka_message, groups|
      key = [kafka_message.topic, kafka_message.partition]
      groups[key] ||= { key: key, messages: [] }
      groups[key][:messages] << kafka_message
    end
  end

  def enqueue_group(group)
    topic, partition = group.fetch(:key)
    entries = group.fetch(:messages).map { |kafka_message| batch_entry(kafka_message) }

    InventoryEventsBatchJob.perform_later(entries, { 'topic' => topic, 'partition' => partition })
    group.fetch(:messages).each { |kafka_message| mark_as_consumed(kafka_message) }
  end

  def batch_entry(kafka_message)
    payload = JSON.parse(kafka_message.raw_payload)
    {
      'type' => payload['type'],
      'payload' => projected_payload(payload),
      'metadata' => kafka_metadata(kafka_message)
    }
  end

  def projected_payload(event)
    case event['type']
    when 'delete'
      event.slice('id', 'org_id', 'updated', 'timestamp')
    when 'created', 'updated'
      import_payload(event)
    else
      event
    end
  end

  def import_payload(event)
    projected = event.slice('type', 'id')
    projected['host'] = project_host(event['host'] || {})
    projected['platform_metadata'] = project_platform_metadata(event['platform_metadata']) if event['platform_metadata']

    projected
  end

  def project_host(host)
    projected = host.slice(
      'id', 'insights_id', 'account', 'org_id', 'display_name', 'groups', 'tags',
      'stale_timestamp', 'created', 'updated'
    )
    if (profile = host['system_profile'])
      projected['system_profile'] = project_system_profile(profile)
    end

    projected
  end

  def project_platform_metadata(metadata)
    metadata.slice('service', 'request_id', 'org_id', 'b64_identity', 'url', 'metadata')
  end

  # Keep fields consumed by import eligibility, persistence, and policy association.
  def project_system_profile(profile)
    projected = profile.slice('owner_id', 'host_type')
    project_operating_system(profile, projected)
    project_bootc_status(profile, projected)
    project_image_builder(profile, projected)

    projected
  end

  def project_operating_system(profile, projected)
    operating_system = profile['operating_system']
    projected['operating_system'] = operating_system.slice('major', 'minor', 'name') if operating_system
  end

  def project_bootc_status(profile, projected)
    booted = profile.dig('bootc_status', 'booted')
    projected['bootc_status'] = { 'booted' => booted.slice('image_digest') } if booted
  end

  def project_image_builder(profile, projected)
    image_builder = profile['image_builder']
    projected['image_builder'] = image_builder.slice('compliance_policy_id') if image_builder
  end

  def kafka_metadata(kafka_message)
    {
      'topic' => kafka_message.topic,
      'partition' => kafka_message.partition,
      'offset' => kafka_message.offset,
      'timestamp' => kafka_message.timestamp
    }
  end
end
