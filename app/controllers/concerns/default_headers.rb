# frozen_string_literal: true

# Original Author: Kevin Deisz
# https://github.com/rails/rails/commit/f22bc41a92e8f51d6f6da5b840f3364474d6aaba
# https://github.com/rails/rails/pull/32484

# The ActionController::DefaultHeaders is available from Rails 6.0
unless defined? ActionController::DefaultHeaders
  # Allows configuring default headers that will be automatically merged into
  # each response.
  module DefaultHeaders
    extend ActiveSupport::Concern

    class_methods do
      def make_response!(request)
        ActionDispatch::Response.create.tap do |res|
          res.request = request
        end
      end
    end
  end
end
