# frozen_string_literal: true

require 'test_helper'

class ComplianceReportsConsumerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'report message is parsed and job is enqueued' do
    message = stub(:message)
    # rubocop:disable Style/StringLiterals
    # rubocop:disable Metrics/LineLength
    message.expects(:value).returns("{\"rh_account\": \"000001\", \"principal\": \"default_principal\", \"validation\": 1, \"hash\": \"036738d6f4e541c4aa8cfc9f46f5a140\", \"size\": 327, \"service\": \"compliance\", \"url\": \"/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cfc9f46f5a140\"}").at_least_once
    # rubocop:enable Style/StringLiterals
    # rubocop:enable Metrics/LineLength
    SafeDownloader.any_instance.expects(:download)
    consumer = ComplianceReportsConsumer.new
    consumer.expects(:validation_message).with(
      'tmp/storage/036738d6f4e541c4aa8cfc9f46f5a140'
    ).returns('success')
    consumer.expects(:produce).with(
      { 'hash': '036738d6f4e541c4aa8cfc9f46f5a140',
        'validation': 'success' }.to_json,
      topic: 'uploadvalidation'
    )
    assert_enqueued_jobs 1 do
      consumer.process(message)
    end
  end
end
