# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class InventoryEventsConsumerTest < ActiveSupport::TestCase
  setup do
    @message = stub(:message)
    @consumer = InventoryEventsConsumer.new
    DeleteHost.clear
    InventoryHostUpdatedJob.clear
  end

  test 'if message is delete, host is enqueued for deletion' do
    @message.expects(:value).returns(
      '{"type": "delete", '\
      '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", '\
      '"timestamp": "2019-05-13 21:18:15.797921"}'
    ).at_least_once
    @consumer.process(@message)
    assert_equal 1, DeleteHost.jobs.size
  end

  test 'if message is not known, no job is enqueued' do
    @message.expects(:value).returns(
      '{"type": "somethingelse", '\
      '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", '\
      '"timestamp": "2019-05-13 21:18:15.797921"}'
    ).at_least_once
    @consumer.process(@message)
    assert_equal 0, DeleteHost.jobs.size
    assert_equal 0, InventoryHostUpdatedJob.jobs.size
  end

  test 'if message is update, job is enqueued to update hosts' do
    @message.expects(:value).returns(
      '{"type": "updated", '\
      '"host": { "id": "fe314be5-4091-412d-85f6-00cc68fc001b", '\
      '          "display_name": "foo"}}'
    ).at_least_once
    @consumer.process(@message)
    assert_equal 0, DeleteHost.jobs.size
    assert_equal 1, InventoryHostUpdatedJob.jobs.size
  end

  context 'report upload messages' do
    setup do
      ParseReportJob.clear
      SafeDownloader.stubs(:download).returns(['report'])
      IdentityHeader.stubs(:new).returns(OpenStruct.new(valid?: true))
    end

    should 'not leak memory to subsequent messages' do
      @message.stubs(:value).returns({
        host: {
          id: '37f7eeff-831b-5c41-984a-254965f58c0f'
        },
        platform_metadata: {
          service: 'compliance',
          url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
          request_id: '036738d6f4e541c4aa8cfc9f46f5a140'
        }
      }.to_json)
      @consumer.stubs(:validation_message).returns('success')
      @consumer.stubs(:produce)

      @consumer.process(@message)

      assert_equal 1, ParseReportJob.jobs.size
      assert_nil @consumer.instance_variable_get(:@report_contents)
      assert_nil @consumer.instance_variable_get(:@validation_message)
      assert_nil @consumer.instance_variable_get(:@msg_value)
    end

    should 'should queue a ParseReportJob' do
      @message.stubs(:value).returns({
        host: {
          id: '37f7eeff-831b-5c41-984a-254965f58c0f'
        },
        platform_metadata: {
          service: 'compliance',
          url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
          request_id: '036738d6f4e541c4aa8cfc9f46f5a140'
        }
      }.to_json)
      @consumer.stubs(:validation_message).returns('success')
      @consumer.expects(:produce).with(
        {
          'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'success'
        }.to_json,
        topic: Settings.kafka_producer_topics.upload_validation
      )

      @consumer.process(@message)
      assert_equal 1, ParseReportJob.jobs.size
    end

    should 'not parse reports when validation fails' do
      @message.stubs(:value).returns({
        host: {
          id: '37f7eeff-831b-5c41-984a-254965f58c0f'
        },
        platform_metadata: {
          service: 'compliance',
          url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
          request_id: '036738d6f4e541c4aa8cfc9f46f5a140'
        }
      }.to_json)
      # Mock the actual 'sending the validation' to Kafka
      XccdfReportParser.stubs(:new).raises(StandardError.new)
      @consumer.expects(:produce).with(
        {
          'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'failure'
        }.to_json,
        topic: Settings.kafka_producer_topics.upload_validation
      )

      @consumer.process(@message)
      assert_equal 0, ParseReportJob.jobs.size
    end

    should 'not parse reports if the entitlement check fails' do
      IdentityHeader.stubs(:new).returns(OpenStruct.new(valid?: false))
      @message.stubs(:value).returns({
        host: {
          id: '37f7eeff-831b-5c41-984a-254965f58c0f'
        },
        platform_metadata: {
          service: 'compliance',
          url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
          request_id: '036738d6f4e541c4aa8cfc9f46f5a140'
        }
      }.to_json)
      @consumer.expects(:produce).with(
        {
          'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'failure'
        }.to_json,
        topic: Settings.kafka_producer_topics.upload_validation
      )

      @consumer.process(@message)
      assert_equal 0, ParseReportJob.jobs.size
    end

    should 'notify payload tracker when a report is received' do
      @message.stubs(:value).returns({
        host: {
          id: '37f7eeff-831b-5c41-984a-254965f58c0f'
        },
        platform_metadata: {
          service: 'compliance',
          url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
          request_id: '036738d6f4e541c4aa8cfc9f46f5a140'
        }
      }.to_json)
      @consumer.stubs(:download_file)
      XccdfReportParser.stubs(:new)
      @consumer.expects(:produce).with(
        {
          'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'success'
        }.to_json,
        topic: Settings.kafka_producer_topics.upload_validation
      )

      @consumer.process(@message)
    end
  end
end
