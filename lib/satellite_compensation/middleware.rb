# frozen_string_literal: true

# Common space for Insights API stuff
module Insights
  module API
    module Common
      module SatelliteCompensation
        # Rack middleware to compensate issues in Satellite-forwarded requests
        class Middleware
          def initialize(app)
            @app = app
          end

          def call(env)
            if env['HTTP_USER_AGENT'] =~ /foreman/i
              # Sometimes Satellite forwards the client requests with an empty string
              # as content-type and Rails does not like it.
              env['CONTENT_TYPE'] = nil if env['CONTENT_TYPE'] == ''

              # There is an additional branch_id parameter coming from Satellite that
              # fails on the stricter checking of params in our REST API.
              Rack::Request.new(env).delete_param('branch_id')
            end

            @app.call(env)
          end
        end
      end
    end
  end
end
