# frozen_string_literal: true

# Saves all of the information we can parse from a XCCDF report into db
class ParseReportJob
  include Sidekiq::Worker

  def perform(file, message)
    parser = XCCDFReportParser.new(ActiveSupport::Gzip.decompress(file),
                                   message)
    parser.save_all
  rescue ::EmptyMetadataError
    Sidekiq.logger.error(
      "Cannot parse report, no metadata available: #{message}"
    )
  end
end
