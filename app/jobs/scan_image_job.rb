# frozen_string_literal: true

require 'tty-command'

# This job scans openshift imagestreams latest image, then parses the
# report in our system.
class ScanImageJob < ApplicationJob
  def perform(imagestream, profile, b64_identity)
    scanner = ImageScanner.new(imagestream, profile, b64_identity)
    scanner.download_image
    scanner.run_oscap_docker
    scanner.parse_report
  end
end
