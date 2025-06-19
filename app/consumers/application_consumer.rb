# frozen_string_literal: true

# Parent class for all Karafka consumers, contains general logic
class ApplicationConsumer < Karafka::BaseConsumer
  attr_reader :message

  def consume
    log_metadata

    messages.each do |message|
      @message = message

      if attempt > 2
        logger.error 'Discarded message'
        mark_as_consumed(message)
      end

      consume_one
      mark_as_consumed(message)
    end
  end

  protected

  def logger
    Rails.logger
  end

  private

  def log_metadata
    logger.info "Processing from #{messages.metadata.topic}/#{messages.metadata.partition} " \
                "with processing lag #{messages.metadata.processing_lag}"
  end
end
