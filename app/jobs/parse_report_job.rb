# frozen_string_literal: true

require 'xccdf_report_parser'

# Saves all of the information we can parse from a Xccdf report into db
class ParseReportJob
  include Sidekiq::Worker

  def perform(file, message)
    return if cancelled?

    parser = XccdfReportParser.new(ActiveSupport::Gzip.decompress(file),
                                   message)
    parser.save_all
  rescue ::EmptyMetadataError, ::WrongFormatError => e
    Sidekiq.logger.error(
      "Cannot parse report: #{e} - #{message}"
    )
  end

  def cancelled?
    Sidekiq.redis { |c| c.exists("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86_400, 1) }
  end
end
