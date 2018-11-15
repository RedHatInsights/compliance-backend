# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class ComplianceReportsConsumer < ApplicationConsumer
  subscribes_to Settings.platform_kafka_topic

  def process(message)
    @value = JSON.parse(message.value)
    logger.info "Received message, enqueueing: #{message.value}"
    path = "tmp/storage/#{@value['hash']}"
    enqueue_job(path)
  rescue SafeDownloader::DownloadError => error
    logger.error "Error parsing report: #{hash} - #{error.message}"
    validate('failure')
  end

  def validate(validation)
    produce(
      validation_payload(@value['hash'], validation),
      topic: Settings.platform_kafka_validation_topic
    )
  end

  private

  def enqueue_job(path)
    SafeDownloader.download(@value['url'], path)
    validation = validation_message(path)
    if validation == 'success'
      job = ParseReportJob.perform_later(path, @value['rh_account'])
      logger.info "Message enqueued: #{hash} as #{job.job_id}"
    else
      logger.error "Error parsing report: #{@value['hash']}"
    end
    validate(validation)
  end

  def validation_message(path)
    XCCDFReportParser.new(path, @value['rh_account'])
    'success'
  rescue StandardError => error
    logger.error "Error validating report: #{hash} - #{error.message}"
    'failure'
  end

  def validation_payload(hash, result)
    { 'hash': hash, 'validation': result }.to_json
  end

  def logger
    Rails.logger
  end
end
