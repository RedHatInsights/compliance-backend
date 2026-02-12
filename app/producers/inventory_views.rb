# frozen_string_literal: true

# A Kafka producer client for platform.inventory.host-apps (Inventory Views).
class InventoryViews < ApplicationProducer
  TOPIC = Settings.kafka.topics.inventory_host_apps
  INVENTORY_VIEW_APPLICATION = 'compliance'

  def self.deliver(request_id:, system:)
    kafka&.produce_sync(
      payload: build_payload(system).to_json,
      headers: build_headers(request_id),
      topic: self::TOPIC
    )
  rescue *EXCEPTIONS => e
    logger.error("InventoryViews delivery failed: #{e}")
  end

  def self.build_headers(request_id)
    { 'application' => INVENTORY_VIEW_APPLICATION, 'request_id' => request_id }
  end

  def self.build_payload(system)
    {
      org_id: system.org_id,
      timestamp: DateTime.now.iso8601,
      hosts: [{ id: system.id, data: host_data(system) }]
    }
  end

  def self.host_data(system)
    {
      policies: system.policies.map { |p| { id: p.id, title: p.title } },
      last_scan: system.last_check_in
    }
  end
end
