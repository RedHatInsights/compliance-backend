# frozen_string_literal: true

require 'test_helper'

class ParseReportJobTest < ActiveSupport::TestCase
  setup do
    @msg_value = { 'id': '', 'account': '', 'request_id': '' }
    @parse_report_job = ParseReportJob.new
    @file = file_fixture('report.tar.gz').read
    @parser = mock('XccdfReportParser')
  end

  test 'payload tracker is notified about successful processing' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all)
    Sidekiq.stubs(:redis).returns(false)
    @parse_report_job.stubs(:jid).returns('1')
    PayloadTracker.expects(:deliver).with(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: :processing,
      status_msg: 'Job 1 is now processing'
    )
    PayloadTracker.expects(:deliver).with(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: :success,
      status_msg: 'Job 1 has completed successfully'
    )
    @parse_report_job.perform(@file, @msg_value)
  end

  test 'payload tracker is notified about errored processing' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all).raises(WrongFormatError)
    Sidekiq.stubs(:redis).returns(false)
    @parse_report_job.stubs(:jid).returns('1')
    PayloadTracker.expects(:deliver).with(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: :processing,
      status_msg: 'Job 1 is now processing'
    )
    error_msg = @msg_value.to_json
    PayloadTracker.expects(:deliver).with(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: :error,
      status_msg: "Cannot parse report: WrongFormatError - #{error_msg}"
    )
    @parse_report_job.perform(@file, @msg_value)
  end
end
