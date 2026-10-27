# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class InventoryEventsConsumer < ApplicationConsumer
  NON_INSIGHTS_ID = '00000000-0000-0000-0000-000000000000'
  MAX_RETRIES = 3

  def consume_one
    case message_type
    when 'delete'
      SystemDeleteJob.perform_later(payload, kafka_metadata)
    when 'created', 'updated'
      SystemImportJob.perform_later(import_payload, kafka_metadata)
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
    JSON.parse(@message.raw_payload)
  end

  def import_payload
    event = payload
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

  def service
    payload.dig('platform_metadata', 'service')
  end

  def message_type
    payload.dig('type')
  end

  def kafka_metadata
    {
      'topic' => @message.topic,
      'partition' => @message.partition,
      'offset' => @message.offset,
      'timestamp' => @message.timestamp
    }
  end
end
