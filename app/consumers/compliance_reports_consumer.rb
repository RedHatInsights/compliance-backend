class ComplianceReportsConsumer < Racecar::Consumer
  subscribes_to 'testareno'

  def process(message)
    puts "Received message: #{message.value}"
  end
end
