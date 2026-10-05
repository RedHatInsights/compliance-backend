# frozen_string_literal: true

class SystemImportJob < ApplicationJob
  queue_as :imports

  def perform(message)
    Kafka::SystemImporter.new(message, Rails.logger, terminal_attempt: false).import if importable_host?(message)
    Kafka::PolicySystemImporter.new(message, Rails.logger).import if policy_id(message)
    Kafka::ReportParser.new(message, Rails.logger).parse_reports if compliance?(message)
  end

  private

  def importable_host?(message)
    insights_id = message.dig('host', 'insights_id')
    insights_id.present? && insights_id != InventoryEventsConsumer::NON_INSIGHTS_ID && !excluded_host_type?(message)
  end

  def excluded_host_type?(message)
    profile = message.dig('host', 'system_profile') || {}

    profile['host_type'] == 'edge' ||
      profile.dig('operating_system', 'name')&.match?(/centos/i) ||
      profile.dig('bootc_status', 'booted', 'image_digest').present?
  end

  def policy_id(message)
    message.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
  end

  def compliance?(message)
    message.dig('platform_metadata', 'service') == 'compliance'
  end
end
