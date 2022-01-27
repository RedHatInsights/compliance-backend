# frozen_string_literal: true

# Common space for Insights API stuff
module Insights
  module API
    module Common
      module SatelliteCompensation
        # Rack middleware to set content-type for Satellite-forwarded requests
        class Middleware
          def initialize(app)
            @app = app
          end

          def call(env)
            # Sometimes Satellite forwards the client requests with an empty string
            # as content-type and Rails does not like it.
            if env['HTTP_USER_AGENT'] =~ /foreman/i && env['CONTENT_TYPE'] == ''
              env['CONTENT_TYPE'] = nil
            end

            @app.call(env)
          end
        end
      end
    end
  end
end
