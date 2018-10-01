# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class ComplianceReportsConsumer < Racecar::Consumer
  subscribes_to 'compliance'

  def process(message)
    value = JSON.parse(message.value)
    Rails.logger.info "Received message, enqueueing: #{value['hash']}"
    job = ParseReportJob.perform_later(value)
    Rails.logger.info "Message enqueued: #{value['hash']} as #{job.job_id} "\
      "in queue #{job.queue_name}"
  end
end
