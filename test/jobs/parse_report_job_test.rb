# frozen_string_literal: true

require 'test_helper'

class ParseReportJobTest < ActiveSupport::TestCase
  setup do
    @msg_value = { 'id': '', 'account': '', 'payload_id': '' }
    @parse_report_job = ParseReportJob.new
    @file = file_fixture('report.tar.gz').read
    @parser = mock('XccdfReportParser')
  end

  test 'payload tracker is notified about successful processing' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all)
    @parse_report_job.stubs(:cancelled?)
    @parse_report_job.expects(:notify_payload_tracker).with(:processing)
    @parse_report_job.expects(:notify_payload_tracker).with(:success)

    @parse_report_job.perform(@file, @msg_value)
  end

  test 'payload tracker is notified about errored processing' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all).raises(WrongFormatError)
    @parse_report_job.stubs(:cancelled?)
    @parse_report_job.expects(:notify_payload_tracker).with(:processing)
    @parse_report_job.expects(:notify_payload_tracker).with(
      :error, "Cannot parse report: WrongFormatError - #{@msg_value.to_json}"
    )

    @parse_report_job.perform(@file, @msg_value)
  end
end
