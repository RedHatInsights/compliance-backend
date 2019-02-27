# frozen_string_literal: true

require 'test_helper'

class ComplianceReportsConsumerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @message = stub(:message)
    @consumer = ComplianceReportsConsumer.new
    @message.expects(:value).returns(
      '{"account": "000001", "principal": "default_principal", '\
      '"validation":1,"payload_id":"036738d6f4e541c4aa8cfc9f46f5a140",'\
      '"size": 327, "service": "compliance", "url": "/tmp/uploads'\
      '/insights-upload-quarantine/036738d6f4e541c4aa8cfc9f46f5a140"}'
    ).at_least_once
    @tempfile = Tempfile.new
    SafeDownloader.expects(:download).returns(@tempfile)
  end

  test 'report message is parsed and job is enqueued' do
    begin
      @consumer.expects(:validation_message).returns('success')
      @consumer.expects(:produce).with(
        {
          'payload_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'success'
        }.to_json,
        topic: Settings.platform_kafka_validation_topic
      )
      assert_enqueued_jobs 1 do
        @consumer.process(@message)
      end
    ensure
      @tempfile.close
      @tempfile.unlink
    end
  end

  test 'file is deleted even when validation fails' do
    XCCDFReportParser.expects(:new).raises(StandardError, 'something broke')
    @tempfile.expects(:close)
    # After calling .close, @tempfile changes its internal object id, so we
    # need to expect any tempfile to close.
    File.expects(:delete).with(@tempfile.path)
    # Mock the actual 'sending the validation' to Kafka
    @consumer.expects(:send_validation).with('failure').returns(true)
    assert_enqueued_jobs 0 do
      @consumer.process(@message)
    end
  end
end
