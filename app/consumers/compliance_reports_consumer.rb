# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class ComplianceReportsConsumer < Racecar::Consumer
  subscribes_to 'compliance'

  def process(message)
    logger.info "Received message, enqueueing: #{message.value}"
    job = ParseReportJob.perform_later(
      SafeDownloader.new.download(
        JSON.parse(message.value)['url']
      ).path
    )
    logger.info "Message enqueued: #{message.value} as #{job.job_id}"
  end

  private

  def logger
    Rails.logger
  end
end
