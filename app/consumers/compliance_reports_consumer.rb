# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class ComplianceReportsConsumer < ApplicationConsumer
  subscribes_to Settings.platform_kafka_topic

  def process(message)
    @msg_value = JSON.parse(message.value)
    logger.info "Received message, enqueueing: #{message.value}"
    download_file
    enqueue_job
  rescue SafeDownloader::DownloadError => e
    logger.error "Error parsing report: #{@msg_value['payload_id']}"\
      " - #{e.message}"
    send_validation('failure')
  end

  def send_validation(validation)
    produce(
      validation_payload(@msg_value['payload_id'], validation),
      topic: Settings.platform_kafka_validation_topic
    )
  end

  private

  def download_file
    @file = SafeDownloader.download(@msg_value['url'], @msg_value['payload_id'])
    @file_contents = @file.read
  end

  def enqueue_job
    if validate == 'success'
      job = ParseReportJob.perform_async(
        ActiveSupport::Gzip.compress(@file_contents), @msg_value
      )
      logger.info "Message enqueued: #{@msg_value['payload_id']} as #{job}"
    else
      logger.error "Error parsing report: #{@msg_value['payload_id']}"
    end
  end

  def validate
    message = validation_message
    send_validation(message)
    message
  end

  def validation_message
    XCCDFReportParser.new(@file_contents, @msg_value)
    'success'
  rescue StandardError => e
    logger.error "Error validating report: #{@msg_value['payload_id']}"\
      " - #{e.message}"
    @file.close
    File.delete(@file.path)
    'failure'
  end

  def validation_payload(payload_id, result)
    {
      'payload_id': payload_id,
      'service': 'compliance',
      'validation': result
    }.to_json
  end

  def logger
    Rails.logger
  end
end
