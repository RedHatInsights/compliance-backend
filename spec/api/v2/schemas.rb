# frozen_string_literal: true

Dir['./spec/api/v2/schemas/*.rb'].each { |file| require file }

module Api
  module V2
    # :nodoc:
    module Schemas
      include Errors
      include Metadata
      include SecurityGuide

      SCHEMAS = {
        id: UUID,
        links: LINKS,
        metadata: METADATA,
        security_guide: SECURITY_GUIDE,
        errors: ERRORS
      }.freeze
    end
  end
end
