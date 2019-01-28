# frozen_string_literal: true

# Saves all of the information we can parse from a XCCDF report into db
class ParseReportJob < ApplicationJob
  def perform(file, account, b64_identity)
    parser = XCCDFReportParser.new(file, account, b64_identity)
    parser.save_rule_results
  ensure
    File.delete(file)
  end

  rescue_from(OpenSCAP::OpenSCAPError) do |e|
    Rails.logger.error "Failed to process message #{e}"
  end
end
