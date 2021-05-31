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

  test 'handles plaintext settings' do
    Settings.kafka.security_protocol = 'plaintext'

    class MockProducer < ApplicationProducer; end

    config = {
      client_id: ApplicationProducer::CLIENT_ID
    }

    assert_equal config, MockProducer.send(:kafka_config)
  end
end
