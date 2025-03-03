# frozen_string_literal: true

# Common space for Insights API stuff
module Insights
  module Api
    module Common
      module SatelliteCompensation
        # Rack middleware to compensate issues in Satellite-forwarded requests
        class Middleware
          def initialize(app)
            @app = app
          end

          def call(env)
            if env['HTTP_USER_AGENT'] =~ /foreman|satellite/i && env['CONTENT_TYPE'] == ''
              # Sometimes Satellite forwards the client requests with an empty string
              # as content-type and Rails does not like it.
              env['CONTENT_TYPE'] = nil
            end

            @app.call(env)
          end
        end
      end
    end
  end
end
