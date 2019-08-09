# frozen_string_literal: true

# Saves all of the information we can parse from a XCCDF report into db
class ParseReportJob
  include Sidekiq::Worker

  def perform(file, message)
    return if cancelled?

    parser = XCCDFReportParser.new(ActiveSupport::Gzip.decompress(file),
                                   message)
    parser.save_all
  rescue ::EmptyMetadataError
    Sidekiq.logger.error(
      "Cannot parse report, no metadata available: #{message}"
    )
  end

  def cancelled?
    Sidekiq.redis { |c| c.exists("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86_400, 1) }
  end
end
