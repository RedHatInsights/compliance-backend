# frozen_string_literal: true

# Parent class for all Karafka consumers, contains general logic
class ApplicationConsumer < Karafka::BaseConsumer
  attr_reader :message

  def consume
    Rails.application.executor.wrap do
      log_metadata
      messages.each { |message| process(message) }
    end
  end

  protected

  def logger
    Rails.logger
  end

  private

  def process(message)
    @message = message
    consume_one
    mark_as_consumed(message)
  end

  def log_metadata
    logger.info "Processing from #{messages.metadata.topic}/#{messages.metadata.partition} " \
                "with processing lag #{messages.metadata.processing_lag}"
  end
end
