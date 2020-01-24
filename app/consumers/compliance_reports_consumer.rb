# frozen_string_literal: true

# Raise an error if entitlement is not available
class EntitlementError < StandardError; end

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class ComplianceReportsConsumer < ApplicationConsumer
  subscribes_to Settings.platform_kafka_topic

  def process(message)
    @msg_value = JSON.parse(message.value)
    raise EntitlementError unless identity.valid?

    download_file
    enqueue_job
    notify_payload_tracker(:received)
  rescue EntitlementError, SafeDownloader::DownloadError => e
    error_message = "Error parsing report: #{message_id} - #{e.message}"
    logger.error error_message
    notify_payload_tracker(:error, error_message)
    send_validation('failure')
  end

  def send_validation(validation)
    produce(
      validation_payload(message_id, validation),
      topic: Settings.platform_kafka_validation_topic
    )
  end

  private

  def notify_payload_tracker(status, status_msg = '')
    PayloadTracker.deliver(
      account: @msg_value['account'], system_id: @msg_value['id'],
      payload_id: @msg_value['request_id'], status: status,
      status_msg: status_msg
    )
  end

  def identity
    IdentityHeader.new(@msg_value['b64_identity'])
  end

  def message_id
    @msg_value.fetch('request_id', @msg_value.dig('payload_id'))
  end

  def download_file
    @report_contents = SafeDownloader.download(@msg_value['url'])
  end

  def enqueue_job
    return unless validate == 'success'

    logger.info "Received message, enqueueing: #{@msg_value}"
    @report_contents.each do |report|
      job = ParseReportJob.perform_async(
        ActiveSupport::Gzip.compress(report), @msg_value
      )
      logger.info "Message enqueued: #{message_id} as #{job}"
    end
  end

  def validate
    message = validation_message
    send_validation(message)
    message
  end

  def validation_message
    @report_contents.each do |report|
      XccdfReportParser.new(report, @msg_value)
    end
    'success'
  rescue StandardError => e
    logger.error "Error validating report: #{message_id}"\
      " - #{e.message}"
    'failure'
  end

  def validation_payload(request_id, result)
    {
      'payload_id': request_id,
      'request_id': request_id,
      'service': 'compliance',
      'validation': result
    }.to_json
  end

  def logger
    Rails.logger
  end
end
