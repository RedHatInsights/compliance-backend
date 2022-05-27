# frozen_string_literal: true

require 'test_helper'

class ParseReportJobTest < ActiveSupport::TestCase
  setup do
    @host = FactoryBot.create(:host, account: '1234')
    @msg_value = {
      'id' => @host.id,
      'account' => '1234',
      'org_id' => '1111',
      'request_id' => '',
      'url' => ''
    }
    @parse_report_job = ParseReportJob.new
    @file = file_fixture('report.tar.gz').read
    @parser = mock('XccdfReportParser')
    @policy = mock('Policy')
    @host = mock('Host')
    @host.stubs(:id)
    @issue_id = 'ssg:rhel7|short_profile_ref_id|rule_ref_id'
    @logger = mock

    @parser.stubs(:policy).returns(@policy)
    @parser.stubs(:host).returns(@host)
    @policy.stubs(:compliant?).returns(false)

    Sidekiq.stubs(:logger).returns(@logger)
    @logger.stubs(:info)
    @logger.stubs(:error)
    @hosts = mock
    @hosts.stubs(:where).returns([1])
    @policy.stubs(:test_result_hosts).returns(@hosts)
  end

  test 'payload tracker is notified about successful processing' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all)
    Sidekiq.stubs(:redis).returns(false)
    @parse_report_job.stubs(:jid).returns('1')
    @parse_report_job
      .stubs(:remediation_issue_ids)
      .returns([@issue_id])
    profile_stub = OpenStruct.new(
      test_result: OpenStruct.new(profile_id: 'profileid')
    )
    @parser.stubs(:supported?).returns(true)
    @parser.stubs(:test_result_file).returns(profile_stub)
    @parser.stubs(:host_profile)
           .returns(OpenStruct.new(policy_id: 'policyUUID'))
    PayloadTracker.expects(:deliver).with(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: :processing,
      status_msg: 'Job 1 is now processing', org_id: @msg_value['org_id']
    )
    PayloadTracker.expects(:deliver).with(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: :success,
      status_msg: 'Job 1 has completed successfully', org_id: @msg_value['org_id']
    )
    SafeDownloader.expects(:download_reports)
                  .with('', ssl_only: Settings.report_download_ssl_only)
                  .returns(ActiveSupport::Gzip.decompress(@file))
    @parse_report_job.perform(0, @msg_value)
    assert_audited 'Successful report of profileid policy policyUUID'
  end

  test 'remediation service is notified about results with failed issues' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all)
    profile_stub = OpenStruct.new(
      test_result: OpenStruct.new(profile_id: 'profileid')
    )
    @parser.stubs(:test_result_file).returns(profile_stub)
    @parser.stubs(:supported?).returns(true)
    @parser.stubs(:host_profile)
           .returns(OpenStruct.new(policy_id: 'policyUUID'))
    Sidekiq.stubs(:redis).returns(false)
    @parse_report_job.stubs(:jid).returns('1')
    @parse_report_job
      .stubs(:remediation_issue_ids)
      .returns([@issue_id])
    RemediationUpdates.expects(:deliver).with(
      host_id: @msg_value['id'],
      issue_ids: [@issue_id]
    )
    SafeDownloader.expects(:download_reports)
                  .with('', ssl_only: Settings.report_download_ssl_only)
                  .returns(ActiveSupport::Gzip.decompress(@file))
    @parse_report_job.perform(0, @msg_value)
  end

  test 'notification service is notified about failed report parsing with no host' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all).raises(
      XccdfReportParser::WrongFormatError.new('Wrong format or benchmark')
    )
    profile_stub = OpenStruct.new(
      test_result: OpenStruct.new(profile_id: 'profileid')
    )
    @parser.stubs(:test_result_file).returns(profile_stub)
    Sidekiq.stubs(:redis).returns(false)
    @parse_report_job.stubs(:jid).returns('1')

    Host.stubs(:find_by).returns(nil)

    ReportUploadFailed.expects(:deliver).with(
      account_number: @msg_value['account'], host: nil, request_id: '', org_id: @msg_value['org_id'],
      error: "Failed to parse report profileid from host #{@msg_value['id']}: WrongFormatError"
    )

    SafeDownloader.expects(:download_reports)
                  .with('', ssl_only: Settings.report_download_ssl_only)
                  .returns(ActiveSupport::Gzip.decompress(@file))
    @parse_report_job.perform(0, @msg_value)
    assert_audited 'Failed to parse report profileid'
  end

  test 'notification service is notified about failed report parsing' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all).raises(
      XccdfReportParser::WrongFormatError.new('Wrong format or benchmark')
    )
    profile_stub = OpenStruct.new(
      test_result: OpenStruct.new(profile_id: 'profileid')
    )
    @parser.stubs(:test_result_file).returns(profile_stub)
    Sidekiq.stubs(:redis).returns(false)
    @parse_report_job.stubs(:jid).returns('1')

    Host.stubs(:find_by).returns(@host)

    ReportUploadFailed.expects(:deliver).with(
      account_number: @msg_value['account'], host: @host, request_id: '', org_id: @msg_value['org_id'],
      error: "Failed to parse report profileid from host #{@msg_value['id']}: WrongFormatError"
    )

    SafeDownloader.expects(:download_reports)
                  .with('', ssl_only: Settings.report_download_ssl_only)
                  .returns(ActiveSupport::Gzip.decompress(@file))
    @parse_report_job.perform(0, @msg_value)
    assert_audited 'Failed to parse report profileid'
  end

  test 'payload tracker is notified about errored processing' do
    XccdfReportParser.stubs(:new).returns(@parser)
    @parser.stubs(:save_all).raises(
      XccdfReportParser::WrongFormatError.new('Wrong format or benchmark')
    )
    profile_stub = OpenStruct.new(
      test_result: OpenStruct.new(profile_id: 'profileid')
    )
    @parser.stubs(:test_result_file).returns(profile_stub)
    Sidekiq.stubs(:redis).returns(false)
    @parse_report_job.stubs(:jid).returns('1')
    PayloadTracker.expects(:deliver).with(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: :processing,
      status_msg: 'Job 1 is now processing', org_id: @msg_value['org_id']
    )
    error_msg = @msg_value.to_json
    PayloadTracker.expects(:deliver).with(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: :error,
      status_msg:
      "Failed to parse report profileid from host #{@msg_value['id']}: XccdfReportParser::WrongFormatError:" \
      " Wrong format or benchmark - #{error_msg}", org_id: @msg_value['org_id']
    )
    SafeDownloader.expects(:download_reports)
                  .with('', ssl_only: Settings.report_download_ssl_only)
                  .returns(ActiveSupport::Gzip.decompress(@file))
    @parse_report_job.perform(0, @msg_value)
    assert_audited 'Failed to parse report profileid'
  end

  test 'no parsed data with parsing failure' do
    XccdfReportParser.stubs(:new).raises(XccdfReportParser::WrongFormatError)
    Sidekiq.stubs(:redis).returns(false)
    @parse_report_job.stubs(:jid).returns('1')
    @parse_report_job
      .stubs(:remediation_issue_ids)
      .returns([@issue_id])
    SafeDownloader.expects(:download_reports)
                  .with('', ssl_only: Settings.report_download_ssl_only)
                  .returns(ActiveSupport::Gzip.decompress(@file))
    @parse_report_job.perform(0, @msg_value)
    assert_audited 'Failed to parse report'
  end

  test 'emits notification non compliant without a report' do
    XccdfReportParser.stubs(:new).returns(@parser)
    Sidekiq.stubs(:redis).returns(false)
    @policy.stubs(:compliant?).returns(false)
    @parser.stubs(:score).returns(90)
    @policy.stubs(:compliance_threshold).returns(100)
    @parser.stubs(:supported?).returns(true)
    @hosts.stubs(:where).returns([])

    @parse_report_job.stubs(:notify_payload_tracker)
    @parse_report_job.stubs(:notify_remediation)
    @parse_report_job.stubs(:audit_success)
    @parser.expects(:save_all)

    SystemNonCompliant.expects(:deliver)

    @parse_report_job.perform(0, @msg_value)
  end

  test 'emits notification if compliance drops below threshold' do
    XccdfReportParser.stubs(:new).returns(@parser)
    Sidekiq.stubs(:redis).returns(false)
    @policy.stubs(:compliant?).returns(true)
    @parser.stubs(:score).returns(90)
    @policy.stubs(:compliance_threshold).returns(100)
    @parser.stubs(:supported?).returns(true)

    @parse_report_job.stubs(:notify_payload_tracker)
    @parse_report_job.stubs(:notify_remediation)
    @parse_report_job.stubs(:audit_success)
    @parser.expects(:save_all)

    SystemNonCompliant.expects(:deliver)

    @parse_report_job.perform(0, @msg_value)
  end

  test 'does not emit notification if host is unsupported' do
    XccdfReportParser.stubs(:new).returns(@parser)
    Sidekiq.stubs(:redis).returns(false)
    @policy.stubs(:compliant?).returns(true)
    @parser.stubs(:score).returns(90)
    @parser.stubs(:supported?).returns(false)
    @policy.stubs(:compliance_threshold).returns(100)

    @parse_report_job.stubs(:notify_payload_tracker)
    @parse_report_job.stubs(:notify_remediation)
    @parse_report_job.stubs(:audit_success)
    @parser.expects(:save_all)

    SystemNonCompliant.expects(:deliver).never

    @parse_report_job.perform(0, @msg_value)
  end

  test 'does not emit notification if compliance is already below threshold' do
    XccdfReportParser.stubs(:new).returns(@parser)
    Sidekiq.stubs(:redis).returns(false)
    @parser.stubs(:score).returns(90)
    @policy.stubs(:compliance_threshold).returns(100)
    @parser.stubs(:supported?).returns(true)

    @parse_report_job.stubs(:notify_payload_tracker)
    @parse_report_job.stubs(:notify_remediation)
    @parse_report_job.stubs(:audit_success)
    @parser.expects(:save_all)

    SystemNonCompliant.expects(:deliver).never

    @parse_report_job.perform(0, @msg_value)
  end

  test 'does not emit notification if compliance increases above threshold' do
    XccdfReportParser.stubs(:new).returns(@parser)
    Sidekiq.stubs(:redis).returns(false)
    @policy.stubs(:compliant?).returns(true)
    @parser.stubs(:score).returns(90)
    @policy.stubs(:compliance_threshold).returns(80)
    @parser.stubs(:supported?).returns(true)

    @parse_report_job.stubs(:notify_payload_tracker)
    @parse_report_job.stubs(:notify_remediation)
    @parse_report_job.stubs(:audit_success)
    @parser.expects(:save_all)

    SystemNonCompliant.expects(:deliver).never

    @parse_report_job.perform(0, @msg_value)
  end

  test 'does not emit notification if report is external' do
    XccdfReportParser.stubs(:new).returns(@parser)
    Sidekiq.stubs(:redis).returns(false)
    @parser.stubs(:policy).returns(nil)
    @parser.stubs(:score).returns(90)
    @parser.stubs(:supported?).returns(true)

    @parse_report_job.stubs(:notify_payload_tracker)
    @parse_report_job.stubs(:notify_remediation)
    @parse_report_job.stubs(:audit_success)
    @parser.expects(:save_all)

    SystemNonCompliant.expects(:deliver).never

    @parse_report_job.perform(0, @msg_value)
  end
end
