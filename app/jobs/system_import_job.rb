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

  def perform(message, _kafka_metadata)
    Kafka::SystemImporter.new(message, Rails.logger, terminal_attempt: terminal_import_attempt?).import
    Kafka::PolicySystemImporter.new(message, Rails.logger).import if policy_id(message)
    Kafka::ReportParser.new(message, Rails.logger).parse_reports if compliance?(message)
  end

  private

  def terminal_import_attempt?
    (exception_executions || {}).fetch(DATABASE_RETRY_HANDLER, 0) >= 2
  end

  def policy_id(message)
    message.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
  end

  def compliance?(message)
    message.dig('platform_metadata', 'service') == 'compliance'
  end
end
