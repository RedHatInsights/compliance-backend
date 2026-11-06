# frozen_string_literal: true

require 'rails_helper'

describe Kafka::ReportParser do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
    ParseReportJob.queue_adapter = ActiveJob::Base.queue_adapter
  end

  let(:service) { Kafka::ReportParser.new(message, Karafka.logger) }
  let(:current_user) { FactoryBot.create(:user, :with_cert_auth) }
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
  let(:policy) { FactoryBot.create(:policy, account: current_user.account) }

  context 'when the system is tombstoned' do
    before { system.update!(deleted_at: Time.current) }

    it 'logs an intentional skip without downloading or reporting a failure' do
      expect(SafeDownloader).not_to receive(:download_reports)
      expect(Karafka.logger).to receive(:info).with(
        a_string_matching(/tombstoned system #{system.id}/)
      )
      expect(Karafka.logger).not_to receive(:audit_fail)
      expect(ReportUploadFailed).not_to receive(:deliver)
      expect(ReportValidation).not_to receive(:deliver)

      service.parse_reports
    end
  end

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
      expect(enqueued_jobs.size).to eq(0)
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
      expect(enqueued_jobs.size).to eq(0)
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
      expect(enqueued_jobs.size).to eq(0)
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
          "[#{org_id}] Error parsing report: #{request_id} - WrongFormatError"
        )
      service.parse_reports
      expect(enqueued_jobs.size).to eq(0)
    end
  end

  context 'with valid reports' do
    let(:profile_id) { 'xccdf_org.ssgproject.content_profile_standard' }
    let(:xml) { file_fixture('xccdf_report.xml').read }
    let(:extracted_xml) { XccdfReportExtractor.extract(xml) }
    let(:parser) do
      instance_double(
        XccdfReportParser,
        validate!: nil,
        extracted_xml: extracted_xml,
        test_result_file: double(test_result: double(profile_id: profile_id))
      )
    end

    before do
      allow(SafeDownloader).to receive(:download_reports)
        .with(nil, ssl_only: Settings.report_download_ssl_only)
        .and_return([xml])
      allow(XccdfReportParser).to receive(:new).and_return(parser)
    end

    it 'downloads reports outside the system lock transaction' do
      transaction_open = false
      allow(ActiveRecord::Base).to receive(:transaction).and_wrap_original do |original, &block|
        original.call do
          transaction_open = true
          begin
            block.call
          ensure
            transaction_open = false
          end
        end
      end
      allow(SafeDownloader).to receive(:download_reports).and_wrap_original do
        expect(transaction_open).to be(false)
        [xml]
      end

      service.parse_reports
    end

    it 'enqueues reports inside a short system lock transaction' do
      transaction_open = false
      allow(ActiveRecord::Base).to receive(:transaction).and_wrap_original do |original, &block|
        original.call do
          transaction_open = true
          begin
            block.call
          ensure
            transaction_open = false
          end
        end
      end
      allow(ParseReportJob).to receive(:perform_later).and_wrap_original do |original, *args|
        expect(transaction_open).to be(true)
        original.call(*args)
      end

      service.parse_reports
    end

    it 'does not report failure when a system is tombstoned before enqueue' do
      allow(service).to receive(:enqueue_parsing_job).and_return([nil, true])
      expect(ReportUploadFailed).not_to receive(:deliver)
      expect(Karafka.logger).not_to receive(:audit_fail)

      service.parse_reports

      expect(enqueued_jobs).to be_empty
    end

    it 'validates each report and enqueues it as a packed payload' do
      expect(parser).to receive(:validate!).once

      expect(Karafka.logger)
        .to receive(:audit_success)
        .with(
          a_string_matching(
            /\A\[#{org_id}\] Enqueued 1 report\(s\) from request #{request_id}: #{profile_id}:\S+\z/
          )
        )

      service.parse_reports

      expect(enqueued_jobs.size).to eq(1)
      expect(ReportArtifact.unpack(enqueued_jobs.first[:args].first)).to eq(extracted_xml)
      expect(extracted_xml.length).to be < xml.length
    end

    it 'resets the enqueued reports when the parser is reused' do
      expect(Karafka.logger).to receive(:audit_success).with(
        a_string_matching(/Enqueued 1 report\(s\) from request #{request_id}: #{profile_id}:\S+\z/)
      ).twice

      service.parse_reports
      service.parse_reports

      expect(enqueued_jobs.size).to eq(2)
    end
  end
end
