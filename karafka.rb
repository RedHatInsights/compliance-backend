# frozen_string_literal: true

class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { 'bootstrap.servers': Settings.kafka.brokers }
    config.client_id = 'compliance_backend'

    # Wait for at least 1 seconds after an error
    config.pause_timeout = 1_000

    config.consumer_persistence = !Rails.env.development?
  end

  Karafka.monitor.subscribe(
    Karafka::Instrumentation::LoggerListener.new(
      log_polling: true
    )
  )

  Karafka.producer.monitor.subscribe(
    WaterDrop::Instrumentation::LoggerListener.new(
      Karafka.logger,
      log_messages: false
    )
  )

  routes.draw do
    topic Settings.kafka.topics.inventory_events do
      consumer InventoryEventsConsumer
    end
  end
end
