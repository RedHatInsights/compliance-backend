# frozen_string_literal: true

# Module to handle RecordNotFound on jobs
module RecordNotFound
  def rescue_not_found
    yield
  rescue ActiveRecord::RecordNotFound => e
    Sidekiq.logger.info(
      "#{e.message} (#{e.class}) "\
      '- this host ID was not registered in Compliance'
    )
  end
end
