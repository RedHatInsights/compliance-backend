# frozen_string_literal: true

# A Kafka producer client for testing connectivity
class TestProducer < ApplicationProducer
  TOPIC = Settings.kafka_producer_topics.test

  def self.deliver
    deliver_message(msg: 'ping')
  end
end
