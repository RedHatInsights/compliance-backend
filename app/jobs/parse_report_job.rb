# frozen_string_literal: true

# Saves all of the information we can parse from a XCCDF report into db
class ParseReportJob < ApplicationJob
  def perform(message)
    # Handle URL differently if it looks like HTTPS URL vs filepath
    parser = XCCDFReportParser.new(message['url'])
    parser.save_host
    parser.save_profiles
    parser.save_rule_results
  end

  rescue_from(OpenSCAP::OpenSCAPError) do |e|
    Rails.logger.error "Failed to process message #{e}"
  end
end
