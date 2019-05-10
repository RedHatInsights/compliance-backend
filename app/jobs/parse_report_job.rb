# frozen_string_literal: true

# Saves all of the information we can parse from a XCCDF report into db
class ParseReportJob
  include Sidekiq::Worker

  def perform(file, account, b64_identity)
    parser = XCCDFReportParser.new(ActiveSupport::Gzip.decompress(file),
                                   account, b64_identity)
    parser.save_all
  end
end
