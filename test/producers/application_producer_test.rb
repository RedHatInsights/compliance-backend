# frozen_string_literal: true

require 'test_helper'

class ApplicationProducerTest < ActiveSupport::TestCase
  teardown do
    Settings.reload!
  end

  test 'handles SSL settings' do
    Settings.kafka.brokers = 'kafka:29092'
    Settings.kafka.security_protocol = 'ssl'
    Settings.kafka.ssl_ca_location = 'test/fixtures/files/test_ca.crt'

    class MockProducer < ApplicationProducer; end

    config = {
      'client.id' => ApplicationProducer::CLIENT_ID,
      'ssl.ca.location' => 'test/fixtures/files/test_ca.crt',
      'bootstrap.servers' => 'kafka:29092'
    }
    assert_equal config, MockProducer.send(:kafka_config)
  end

  test 'handles SASL SSL settings' do
    Settings.kafka.brokers = 'kafka:29092'
    Settings.kafka.security_protocol = 'sasl_ssl'
    Settings.kafka.ssl_ca_location = 'test/fixtures/files/test_ca.crt'
    Settings.kafka.sasl_username = 'user'
    Settings.kafka.sasl_password = 'youwish'
    Settings.kafka.sasl_mechanism = 'SCRAM-SHA-512'

    class MockProducer < ApplicationProducer; end

    config = {
      'bootstrap.servers' => 'kafka:29092',
      'client.id' => ApplicationProducer::CLIENT_ID,
      'ssl.ca.location' => 'test/fixtures/files/test_ca.crt',
      'sasl.username' => 'user',
      'sasl.password' => 'youwish',
      'sasl.mechanism' => 'SCRAM-SHA-512'
    }

    assert_equal config, MockProducer.send(:kafka_config)
  end

  test 'handles plaintext settings' do
    Settings.kafka.security_protocol = 'plaintext'
    Settings.kafka.brokers = 'kafka:29092'

    class MockProducer < ApplicationProducer; end

    config = {
      'client.id' => ApplicationProducer::CLIENT_ID,
      'bootstrap.servers' => 'kafka:29092'
    }

    assert_equal config, MockProducer.send(:kafka_config)
  end
end
