# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module TailoringFile
        extend Api::V2::Schemas::Util

        TAILORING_FILE = begin
          # Download the JSON:API schema from GitHub
          json = JSON.parse(Net::HTTP.get(URI.parse('https://raw.githubusercontent.com/ComplianceAsCode/schemas/main/tailoring/schema.json')))

          # Delete the unwanted keys that rswag can't parse
          json.delete('$schema')
          json.delete('$id')

          json
        end.freeze
      end
    end
  end
end
