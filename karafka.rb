# frozen_string_literal: true

class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { 'bootstrap.servers': Settings.kafka.brokers }
    config.client_id = 'compliance_backend'
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
