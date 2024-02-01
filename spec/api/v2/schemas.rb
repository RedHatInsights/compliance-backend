# frozen_string_literal: true

Dir['./spec/api/v2/schemas/*.rb'].each { |file| require file }

module Api
  module V2
    module Schemas
      include Metadata
      include SecurityGuides
      include Profiles
      include Rules
      include Policies

      SCHEMAS = {
        id: UUID,
        links: LINKS,
        metadata: METADATA,
        security_guides: SECURITY_GUIDE,
        profiles: PROFILE,
        rules: RULE,
        policies: POLICY
      }.freeze
    end
  end
end
