# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ComplianceConsumer do
  subject(:consumer) { karafka.consumer_for(Settings.kafka.topics.inventory_events) }

  before do
    karafka.produce(message.to_json)
  end

  let(:user) { FactoryBot.create(:v2_user) }
  let(:org_id) { user.org_id }
  let(:system) do
    FactoryBot.create(
      :system,
      account: user.account,
    )
  end
  let(:message) {{
    'type' => type,
    'id' => system.id,
    'timestamp' => Time.current.to_s.chomp(' UTC'),
    'org_id' => org_id # in the case of host deletion `org_id` is on the top level
  }}

  describe 'received compliance report message' do
    let(:type) { 'updated' }
    let(:url) { "/tmp/uploads/insights-upload-quarantine/#{Faker::Alphanumeric.alphanumeric(number: 21)}" }
    let(:request_id) { Faker::Alphanumeric.alphanumeric(number: 32) }
    let(:b64_identity) { user.account.identity_header.raw }
    let(:message) {{
      'type' => type,
      'timestamp' => Time.current.to_s.chomp(' UTC'),
      'host' => { 'id' => system.id },
      'platform_metadata' => {
        'account' => user.account,
        'request_id' => request_id,
        'service' => 'compliance',
        'url' => url,
        'b64_identity' => b64_identity,
        'org_id' => org_id
      }
    }}

    it 'correctly parses the message metadata' do # TODO: change if the implemantion changes
      expect(consumer.send(:metadata)).to eq(
        'b64_identity' => b64_identity,
        'id' => system.id,
        'request_id' => request_id,
        'org_id' => org_id,
        'url' => url
      )
    end

    it 'enqueues a ParseReportJob' do # TODO: moved from ReportParsing tests - will be moved in implementation as well
      # TODO: this test is utter chaos, need to restructure
      # almost working test: (need to mock identity validity)

      # expect(Rails.logger).to receive(:audit_success).with(
      #   "[#{org_id}] Enqueued report parsing of profileid from request #{request_id} as job 1"
      # )
      # subclass.parse_report
      # expect(ParseReportJob.jobs.size).to eq(1)

      # TODO: these two should probably belong to the inventory consumer + test call to `parse_report` there
      # @consumer.stubs(:validated_reports).returns([%w[profileid report]])
      # @consumer.expects(:produce).with(
      #   {
      #     'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
      #     'service': 'compliance',
      #     'validation': 'success'
      #   }.to_json,
      #   topic: Settings.kafka.topics.upload_compliance
      # )

      # assert_audited_success 'Enqueued report parsing of profileid'
      # @consumer.process(@message)
      # assert_equal 1, ParseReportJob.jobs.size
    end

    context 'and a db error occurs' do
      before do
        allow(XccdfReportParser).to receive(:new).and_raise(ActiveRecord::StatementInvalid)
      end

      it 'fails gracefully and clears connections' do # TODO alternative: 'logs error, does not enqueue and clears connections'
        expect(Karafka.logger).to receive(:error).with(
          "[#{org_id}] Database error, clearing active connection for further reconnect"
        )
        expect(ActiveRecord::Base.connection_handler).to receive(:clear_active_connections!)

        expect { consumer.consume }.to raise_error(ActiveRecord::StatementInvalid)

        expect(ParseReportJob.jobs.size).to eq(0)
      end
    end

    context 'and a redis error occurs' do
      before do
        allow(consumer).to receive(:dispatch).and_raise(Redis::CannotConnectError)
      end

      it 'logs the error' do
        expect(Karafka.logger).to receive(:error).with(
          "[#{org_id}] Failed to connect to elasticache/redis"
        )

        expect { consumer.consume }.to raise_error(Redis::CannotConnectError)
      end
    end
  end

  describe 'received unknown message' do
    let(:type) { 'somethingelse' }

    it 'does not enqueue any jobs' do
      expect(Karafka.logger).to receive(:debug).with(
        "Skipped message of type #{type}"
      )

      consumer.consume

      expect(DeleteHost.jobs.size).to eq(0)
      expect(ParseReportJob.jobs.size).to eq(0)
    end
  end
end
