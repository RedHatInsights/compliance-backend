# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class ComplianceReportsConsumer < Racecar::Consumer
  subscribes_to 'compliance'

  def process(message)
    value = JSON.parse(message.value)
    logger.info "Received message, enqueueing: #{message}"
    path = "tmp/storage/#{value['hash']}"
    SafeDownloader.new.download(value['url'], path)
    validation = validation_message(path)
    enqueue_job(path, value['hash'], validation)
    produce(
      validation_payload(value['hash'], validation),
      topic: 'uploadvalidation'
    )
  end

  private

  def enqueue_job(path, hash, validation)
    if validation == 'success'
      job = ParseReportJob.perform_later(path)
      logger.info "Message enqueued: #{hash} as #{job.job_id}"
    else
      logger.error("Error parsing report: #{hash}")
    end
  end

  def validation_message(path)
    XCCDFReportParser.new(path)
    'success'
  rescue StandardError
    'failure'
  end

  def validation_payload(hash, result)
    { 'hash': hash, 'validation': result }.to_json
  end

  def logger
    Rails.logger
  end
end
