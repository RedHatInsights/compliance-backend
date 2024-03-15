# frozen_string_literal: true

Dir['./spec/api/v2/schemas/*.rb'].each { |file| require file }

module Api
  module V2
    # :nodoc:
    module Schemas
      include Errors
      include Metadata
      include Profile
      include RuleGroup
      include SecurityGuide
      include SupportedProfile
      include ValueDefinition

      SCHEMAS = {
        errors: ERRORS,
        id: UUID,
        links: LINKS,
        metadata: METADATA,
        profile: PROFILE,
        rule_group: RULE_GROUP,
        security_guide: SECURITY_GUIDE,
        supported_profile: SUPPORTED_PROFILE,
        value_definition: VALUE_DEFINITION
      }.freeze
    end
  end
end
