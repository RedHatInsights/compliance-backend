class ComplianceReportsConsumer < Racecar::Consumer
  subscribes_to 'compliance'

  def process(message)
    # Handle URL differently if it looks like HTTPS URL vs filepath
    parser = XCCDFReportParser.new(message.value['url'])
    parser.save_host
    parser.save_profiles
    parser.save_rule_results
    puts "Received message: #{message.value}"
  rescue OpenSCAP::OpenSCAPError => e
    puts "Failed to process message in #{message.topic}/#{message.partition} at offset #{message.offset}: #{e}"
  end
end
