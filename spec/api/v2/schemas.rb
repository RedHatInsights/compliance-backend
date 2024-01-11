# frozen_string_literal: true

Dir['./spec/api/v2/schemas/*.rb'].each { |file| require file }

module Api
  module V2
    module Schemas
      include Metadata
      include Policies
      include SecurityGuides
      include Tailorings

      SCHEMAS = {
        id: UUID,
        links: LINKS,
        metadata: METADATA,
        policies: POLICY,
        security_guides: SECURITY_GUIDE,
        tailoring: TAILORING
      }.freeze
    end
  end
end
