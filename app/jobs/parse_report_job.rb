# frozen_string_literal: true

# Saves all of the information we can parse from a XCCDF report into db
class ParseReportJob
  include Sidekiq::Worker

  def perform(file, account, b64_identity)
    parser = XCCDFReportParser.new(ActiveSupport::Gzip.decompress(file),
                                   account, b64_identity)
    parser.save_all
    GC.start
  rescue OpenSCAP::OpenSCAPError => e
    Sidekiq.logger.error "Failed to process message #{e}"
  end
end
