# frozen_string_literal: true

require 'test_helper'

class ApplicationProducerTest < ActiveSupport::TestCase
  class MockProducer < ApplicationProducer
    BROKERS = ['broker1'].freeze
  end

  test 'handles SSL settings' do
    MockProducer::SECURITY_PROTOCOL = 'ssl'
    MockProducer::SSL_CA_LOCATION = 'test/fixtures/files/test_ca.crt'

    config = {
      client_id: ApplicationProducer::CLIENT_ID,
      ssl_ca_cert: "very secure\n"
    }

    assert_equal config, MockProducer.send(:kafka_config)
  end

  test 'handles plaintext settings' do
    MockProducer::SECURITY_PROTOCOL = 'plaintext'

    config = {
      client_id: ApplicationProducer::CLIENT_ID
    }

    assert_equal config, MockProducer.send(:kafka_config)
  end
end
