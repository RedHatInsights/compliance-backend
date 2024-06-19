# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module TailoringFile
        extend Api::V2::Schemas::Util

        FALLBACK_PATH = Rails.root.join('swagger/v2/tailoring_schema.json')

        def self.retrieve_schema
          # Download the JSON:API schema from GitHub
          content = SafeDownloader.download('https://raw.githubusercontent.com/ComplianceAsCode/schemas/main/tailoring/schema.json')
          File.open(FALLBACK_PATH, 'w') { |f| f.write(content.read) }
          content.rewind
          content
        rescue SafeDownloader::DownloadError
          File.read(FALLBACK_PATH)
        end

        TAILORING_FILE = begin
          json = JSON.parse(retrieve_schema)

          # Delete the unwanted keys that rswag can't parse
          json.delete('$schema')
          json.delete('$id')

          # Rename to Tailoring file
          json['title'] = 'Tailoring File'

          json
        end.freeze
      end
    end
  end
end
