# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class ComplianceReportsConsumerTest < ActiveSupport::TestCase
  setup do
    @message = stub(:message)
    @consumer = ComplianceReportsConsumer.new
    ParseReportJob.clear
  end

  test 'report message is parsed and job is enqueued with request_id' do
    SafeDownloader.expects(:download).returns('report')
    @consumer.expects(:identity).returns(OpenStruct.new(valid?: true))
             .at_least_once
    @message.expects(:value).returns(
      '{"account": "000001", "principal": "default_principal", '\
      '"validation":1,"request_id":"036738d6f4e541c4aa8cfc9f46f5a140",'\
      '"size": 327, "service": "compliance", "url": "/tmp/uploads'\
      '/insights-upload-quarantine/036738d6f4e541c4aa8cfc9f46f5a140"}'
    ).at_least_once
    begin
      @consumer.expects(:validation_message).returns('success')
      @consumer.expects(:produce).with(
        {
          'payload_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'success'
        }.to_json,
        topic: Settings.platform_kafka_validation_topic
      )
      @consumer.process(@message)
      assert_equal 1, ParseReportJob.jobs.size
    end
  end

  test 'report message is parsed and job is enqueued with payload_id' do
    SafeDownloader.expects(:download).returns('report')
    @consumer.expects(:identity).returns(OpenStruct.new(valid?: true))
             .at_least_once
    @message.expects(:value).returns(
      '{"account": "000001", "principal": "default_principal", '\
      '"validation":1,"payload_id":"036738d6f4e541c4aa8cfc9f46f5a140",'\
      '"size": 327, "service": "compliance", "url": "/tmp/uploads'\
      '/insights-upload-quarantine/036738d6f4e541c4aa8cfc9f46f5a140"}'
    ).at_least_once
    begin
      @consumer.expects(:validation_message).returns('success')
      @consumer.expects(:produce).with(
        {
          'payload_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'success'
        }.to_json,
        topic: Settings.platform_kafka_validation_topic
      )
      @consumer.process(@message)
      assert_equal 1, ParseReportJob.jobs.size
    end
  end

  test 'file is deleted even when validation fails' do
    SafeDownloader.expects(:download).returns('report')
    @consumer.expects(:identity).returns(OpenStruct.new(valid?: true))
             .at_least_once
    @message.expects(:value).returns(
      '{"account": "000001", "principal": "default_principal", '\
      '"validation":1,"request_id":"036738d6f4e541c4aa8cfc9f46f5a140",'\
      '"size": 327, "service": "compliance", "url": "/tmp/uploads'\
      '/insights-upload-quarantine/036738d6f4e541c4aa8cfc9f46f5a140"}'
    ).at_least_once
    XCCDFReportParser.expects(:new).raises(StandardError, 'something broke')
    # Mock the actual 'sending the validation' to Kafka
    @consumer.expects(:send_validation).with('failure').returns(true)
    @consumer.process(@message)
    assert_equal 0, ParseReportJob.jobs.size
  end

  test 'report is not parsed if entitlement check fails' do
    @consumer.expects(:identity).returns(OpenStruct.new(valid?: false))
             .at_least_once
    @message.expects(:value).returns(
      '{"account": "000001", "principal": "default_principal", '\
      '"validation":1,"request_id":"036738d6f4e541c4aa8cfc9f46f5a140",'\
      '"size": 327, "service": "compliance", "url": "/tmp/uploads'\
      '/insights-upload-quarantine/036738d6f4e541c4aa8cfc9f46f5a140"}'
    ).at_least_once
    @consumer.expects(:send_validation).with('failure')
    @consumer.process(@message)
    assert_equal 0, ParseReportJob.jobs.size
  end
end
