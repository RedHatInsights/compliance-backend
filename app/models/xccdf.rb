# frozen_string_literal: true

Dir[File.join(__dir__, 'xccdf', '*.rb')].each { |f| require f }

# Represents all our models which come directly from the SCAP Xccdf XML format
module Xccdf
end
