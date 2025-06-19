# frozen_string_literal: true

require 'rails_helper'

describe Kafka::ReportParser do
  let(:service) { Kafka::ReportParser.new(message, Karafka.logger) }
  let(:current_user) { FactoryBot.create(:v2_user, :with_cert_auth) }
  let(:org_id) { current_user.org_id }
  let(:request_id) { Faker::Alphanumeric.alphanumeric(number: 32) }
  let(:message) do
    {
      'host' => {
        'id' => system.id,
        'timestamp' => DateTime.now.iso8601(6)
      },
      'platform_metadata' => {
        'b64_identity' => current_user.account.identity_header.raw,
        'request_id' => request_id,
        'org_id' => org_id
      }
    }
  end
  let(:system) { FactoryBot.create(:system, account: current_user.account) }
  let(:policy) { FactoryBot.create(:v2_policy, account: current_user.account) }

  context 'with invalid identity' do
    let(:message) do
      {
        'host' => {
          'id' => system.id,
          'timestamp' => DateTime.now.iso8601(6)
        },
        'platform_metadata' => {
          'b64_identity' => current_user.account.b64_identity,
          'request_id' => request_id,
          'org_id' => org_id
        }
      }
    end

    it 'logs entitlement error' do
      expect(Karafka.logger)
        .to receive(:audit_fail)
        .with(
          a_string_matching([
            /\A\[#{org_id}\] Rejected report with request id \S+: /,
            /invalid identity or missing insights entitlement\z/
          ].join)
        )
      service.parse_reports
      expect(ParseReportJob.jobs.size).to eq(0)
    end
  end

  context 'when report is failing to download' do
    before do
      allow(SafeDownloader).to receive(:download_reports)
        .with(nil, ssl_only: Settings.report_download_ssl_only)
        .and_raise(SafeDownloader::DownloadError)
    end

    it 'logs and raises download error' do
      expect(Karafka.logger)
        .to receive(:audit_fail)
        .with(
          a_string_matching([
            /\A\[#{org_id}\] Failed to download report with request id \S+: /,
            /SafeDownloader::DownloadError\z/
          ].join)
        )
      expect { service.parse_reports }.to raise_error(SafeDownloader::DownloadError)
      expect(ParseReportJob.jobs.size).to eq(0)
    end
  end

  context 'when report contents are empty' do
    before do
      allow(SafeDownloader).to receive(:download_reports)
        .with(nil, ssl_only: Settings.report_download_ssl_only)
        .and_return([])
    end

    it 'logs parse error' do
      expect(Karafka.logger)
        .to receive(:audit_fail)
        .with(
          "[#{org_id}] Invalid report: Report empty"
        )
      service.parse_reports
      expect(ParseReportJob.jobs.size).to eq(0)
    end
  end

  context 'when report is unparsable' do
    before do
      allow(SafeDownloader).to receive(:download_reports)
        .with(nil, ssl_only: Settings.report_download_ssl_only)
        .and_return([file_fixture('wrong_xccdf_report.xml').read])
    end

    it 'logs parse error' do
      expect(Karafka.logger)
        .to receive(:audit_fail)
        .with(
          "[#{org_id}] Invalid report: Report parsing failed"
        )
      service.parse_reports
      expect(ParseReportJob.jobs.size).to eq(0)
    end
  end

  context 'with valid reports' do
    before do
      allow(SafeDownloader).to receive(:download_reports)
        .with(nil, ssl_only: Settings.report_download_ssl_only)
        .and_return([file_fixture('xccdf_report.xml').read])
    end

    let(:profile_id) { 'xccdf_org.ssgproject.content_profile_standard' }

    it 'enqueues report parsing job' do
      expect(Karafka.logger)
        .to receive(:audit_success)
        .with(
          a_string_matching(
            /\A\[#{org_id}\] Enqueued report parsing of #{profile_id} from request #{request_id} as a job \S+\z/
          )
        )

      service.parse_reports

      expect(ParseReportJob.jobs.size).to eq(1)
    end
  end

  after do
    ParseReportJob.clear
  end
end
