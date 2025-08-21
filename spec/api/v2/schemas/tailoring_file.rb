# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module TailoringFile
        extend Api::V2::Schemas::Util

        JSON_FALLBACK_PATH = Rails.root.join('swagger/v2/tailoring_schema.json')
        TOML_FALLBACK_PATH = Rails.root.join('swagger/v2/tailoring_schema_toml.json')

        JSON_SCHEMA_URL = 'https://raw.githubusercontent.com/ComplianceAsCode/schemas/main/tailoring/schema.json'
        # FIXME: after there's a proper schema for TOML, this should be specified
        # https://github.com/osbuild/blueprint-schema
        TOML_SCHEMA_URL = nil

        def self.retrieve_schema(schema_url, fallback)
          # Download the API schema from GitHub
          content = SafeDownloader.download(schema_url)
          File.open(fallback, 'w') { |f| f.write(content.read) }
          content.rewind
          content
        rescue SafeDownloader::DownloadError
          File.read(fallback)
        end

        TAILORING_FILE_JSON = begin
          json = JSON.parse(retrieve_schema(JSON_SCHEMA_URL, JSON_FALLBACK_PATH))

          # Delete the unwanted keys that rswag can't parse
          json.delete('$schema')
          json.delete('$id')

          # Rename to Tailoring file
          json['title'] = 'Tailoring File'

          json
        end.freeze

        TAILORING_FILE_TOML = begin
          # Necessary string conversion due to TOML parser not supporting StringIO
          toml = JSON.parse(retrieve_schema(TOML_SCHEMA_URL, TOML_FALLBACK_PATH))

          # Delete the unwanted keys that rswag can't parse
          toml.delete('$schema')
          toml.delete('$id')

          # Rename to Tailoring file
          toml['name'] = 'Tailoring File Blueprint'

          toml
        end.freeze
      end
    end
  end
end
