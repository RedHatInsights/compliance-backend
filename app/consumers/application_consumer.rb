# frozen_string_literal: true

# Parent class for all Karafka consumers, contains general logic
class ApplicationConsumer < Karafka::BaseConsumer
  attr_reader :message

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def consume
    logger.info "Processing #{messages.metadata.topic}/#{messages.metadata.partition} " \
                "#{messages.metadata.first_offset}-#{messages.metadata.last_offset} " \
                "with processing lag #{messages.metadata.processing_lag}"
    messages.each do |message|
      @message = message

      if attempt > 3
        logger.error 'Discarded message'
        mark_as_consumed(message)
      end

      consume_one
      mark_as_consumed(message)
    end

    logger.info 'Batch consumed'
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  protected

  def logger
    Rails.logger
  end
end
