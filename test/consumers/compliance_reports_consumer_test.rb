# frozen_string_literal: true

require 'test_helper'

class ComplianceReportsConsumerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'report message is parsed and job is enqueued' do
    message = stub(:message)
    message.expects(:value).returns(
      '{"account": "000001", "principal": "default_principal", '\
      '"validation":1,"payload_id":"036738d6f4e541c4aa8cfc9f46f5a140",'\
      '"size": 327, "service": "compliance", "url": "/tmp/uploads'\
      '/insights-upload-quarantine/036738d6f4e541c4aa8cfc9f46f5a140"}'
    ).at_least_once

    begin
      tempfile = Tempfile.new
      SafeDownloader.expects(:download).returns(tempfile)
      consumer = ComplianceReportsConsumer.new
      consumer.expects(:validation_message).returns('success')
      consumer.expects(:produce).with(
        {
          'payload_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'success'
        }.to_json,
        topic: Settings.platform_kafka_validation_topic
      )
      assert_enqueued_jobs 1 do
        consumer.process(message)
      end
    ensure
      tempfile.close
      tempfile.unlink
    end
  end
end
