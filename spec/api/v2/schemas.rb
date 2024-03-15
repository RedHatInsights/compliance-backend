# frozen_string_literal: true

Dir['./spec/api/v2/schemas/*.rb'].each { |file| require file }

module Api
  module V2
    # :nodoc:
    module Schemas
      include Errors
      include Metadata
      include Profile
      include SecurityGuide
      include ValueDefinition

      SCHEMAS = {
        errors: ERRORS,
        id: UUID,
        links: LINKS,
        metadata: METADATA,
        profile: PROFILE,
        security_guide: SECURITY_GUIDE,
        value_definition: VALUE_DEFINITION
      }.freeze
    end
  end
end
