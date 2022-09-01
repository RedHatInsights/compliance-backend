# frozen_string_literal: true

require 'test_helper'

class ApplicationProducerTest < ActiveSupport::TestCase
  teardown do
    Settings.reload!
  end

  test 'handles SSL settings' do
    Settings.kafka.security_protocol = 'ssl'
    Settings.kafka.ssl_ca_location = 'test/fixtures/files/test_ca.crt'

    class MockProducer < ApplicationProducer; end

    config = {
      client_id: ApplicationProducer::CLIENT_ID,
      ssl_ca_cert: "very secure\n"
    }
    assert_equal config, MockProducer.send(:kafka_config)
  end

  test 'handles SASL SSL settings' do
    Settings.kafka.security_protocol = 'sasl_ssl'
    Settings.kafka.ssl_ca_location = 'test/fixtures/files/test_ca.crt'
    Settings.kafka.sasl_username = 'user'
    Settings.kafka.sasl_password = 'youwish'
    Settings.kafka.sasl_mechanism = 'SCRAM-SHA-512'

    class MockProducer < ApplicationProducer; end

    config = {
      client_id: ApplicationProducer::CLIENT_ID,
      ssl_ca_cert: "very secure\n",
      sasl_scram_username: 'user',
      sasl_scram_password: 'youwish',
      sasl_scram_mechanism: 'sha512',
      ssl_ca_certs_from_system: true
    }

    assert_equal config, MockProducer.send(:kafka_config)
  end

  test 'handles plaintext settings' do
    Settings.kafka.security_protocol = 'plaintext'

    class MockProducer < ApplicationProducer; end

    config = {
      client_id: ApplicationProducer::CLIENT_ID
    }

    assert_equal config, MockProducer.send(:kafka_config)
  end
end
