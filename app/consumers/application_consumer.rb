# frozen_string_literal: true

# Parent class for all Karafka consumers, contains general logic
class ApplicationConsumer < Karafka::BaseConsumer
  attr_reader :message

  def consume
    messages.each do |message|
      @message = message

      if retrying?
        logger.debug 'Retrying message'

        if attempt > 2
          logger.error 'Discarded message'
          mark_as_consumed(message)
        end
      end

      consume_one

      logger.info 'Consumed message'

      mark_as_consumed(message)
    end
  end

  protected

  def logger
    Rails.logger
  end
end
