# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class InventoryEventsConsumerTest < ActiveSupport::TestCase
  setup do
    @message = stub(message: nil)
    @consumer = InventoryEventsConsumer.new
    DeleteHost.clear
  end

  test 'if message is delete, host is enqueued for deletion' do
    @message.expects(:value).returns(
      '{"type": "delete", '\
      '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", '\
      '"timestamp": "2019-05-13 21:18:15.797921"}'
    ).at_least_once
    @consumer.process(@message)
    assert_equal 1, DeleteHost.jobs.size
    assert_audited 'Enqueued DeleteHost job for host'
    assert_audited 'fe314be5-4091-412d-85f6-00cc68fc001b'
  end

  test 'if message is delete, and enqueue for deletion fails' do
    @message.expects(:value).returns(
      '{"type": "delete", '\
      '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", '\
      '"timestamp": "2019-05-13 21:18:15.797921"}'
    ).at_least_once
    DeleteHost.stubs(:perform_async).raises(:StandardError)
    assert_raises StandardError do
      @consumer.process(@message)
    end
    assert_audited 'Failed to enqueue DeleteHost'
    assert_audited 'fe314be5-4091-412d-85f6-00cc68fc001b'
  end

  test 'if message is not known, no job is enqueued' do
    @message.expects(:value).returns(
      '{"type": "somethingelse", '\
      '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", '\
      '"timestamp": "2019-05-13 21:18:15.797921"}'
    ).at_least_once
    @consumer.process(@message)
    assert_equal 0, DeleteHost.jobs.size
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
        },
        account: '1234'
      }.to_json)
      @consumer.stubs(:validated_reports).returns([%w[profile report]])
      @consumer.stubs(:produce)

      @consumer.process(@message)

      assert_equal 1, ParseReportJob.jobs.size
      assert_nil @consumer.instance_variable_get(:@report_contents)
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
        },
        account: '1234'
      }.to_json)
      @consumer.stubs(:validated_reports).returns([%w[profileid report]])
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
      assert_audited 'Enqueued report parsing of profileid'
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
        },
        account: '1234'
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
      assert_audited 'Invalid Report'
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
        },
        account: '1234'
      }.to_json)
      @consumer.expects(:validated_reports).never
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
      assert_audited 'Rejected report'
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
        },
        account: '1234'
      }.to_json)
      @consumer.stubs(:download_file)
      parsed_stub = OpenStruct.new(
        test_result_file: OpenStruct.new(
          test_result: OpenStruct.new(profile_id: 'profileid')
        )
      )
      XccdfReportParser.stubs(:new).returns(parsed_stub)
      @consumer.expects(:produce).with(
        {
          'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
          'service': 'compliance',
          'validation': 'success'
        }.to_json,
        topic: Settings.kafka_producer_topics.upload_validation
      )

      @consumer.process(@message)
      assert_audited 'Enqueued report parsing of profileid'
    end

    should 'handle db errors and db clear connections' do
      @message.stubs(:value).returns({
        host: {
          id: '37f7eeff-831b-5c41-984a-254965f58c0f'
        },
        platform_metadata: {
          service: 'compliance',
          url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
          request_id: '036738d6f4e541c4aa8cfc9f46f5a140'
        },
        account: '1234'
      }.to_json)
      # Mock the actual 'sending the validation' to Kafka
      XccdfReportParser.stubs(:new).raises(ActiveRecord::StatementInvalid)

      ActiveRecord::Base.expects(:clear_active_connections!)
      assert_raises ActiveRecord::StatementInvalid do
        @consumer.process(@message)
      end
      assert_equal 0, ParseReportJob.jobs.size
    end
  end
end
