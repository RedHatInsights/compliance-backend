# frozen_string_literal: true

Dir['./spec/api/v2/schemas/*.rb'].each { |file| require file }

module Api
  module V2
    module Schemas
      include Metadata
      include SecurityGuides
      include Profiles

      SCHEMAS = {
        id: UUID,
        links: LINKS,
        metadata: METADATA,
        security_guides: SECURITY_GUIDE,
        profiles: PROFILE
      }.freeze
    end
  end
end
