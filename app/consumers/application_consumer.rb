# frozen_string_literal: true

require 'racecar/consumer'

# Parent class for all Racecar consumers, contains general logic
class ApplicationConsumer < Racecar::Consumer
  def process(message)
    @msg_value = JSON.parse(message.value)
    logger.info "Received message, enqueueing: #{@msg_value}"
  end

  protected

  def logger
    Rails.logger
  end
end
