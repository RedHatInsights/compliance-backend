# frozen_string_literal: true

# Common space for Insights API stuff
module Insights
  module Api
    module Common
      module AdjustTags
        # Rack middleware to adjust params[tags] to be an array
        class Middleware
          def initialize(app)
            @app = app
          end

          def call(env)
            # rubocop:disable Style/RedundantRegexpArgument
            qs = env['QUERY_STRING'].sub(/^tags=/, 'tags[]=')
                                    .gsub(/&tags=/, '&tags[]=')
            # rubocop:enable Style/RedundantRegexpArgument

            # Match the QUERY_STRING at the end of the line only
            re = /#{Regexp.quote(env['QUERY_STRING'])}$/

            env['REQUEST_URI'] = env['REQUEST_URI'].sub(re, qs)
            env['QUERY_STRING'] = qs

            @app.call(env)
          end
        end
      end
    end
  end
end
