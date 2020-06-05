# frozen_string_literal: true

require './spec/api/v1/schemas/types'
require './spec/api/v1/schemas/errors'
require './spec/api/v1/schemas/metadata'
require './spec/api/v1/schemas/hosts'
require './spec/api/v1/schemas/benchmarks'
require './spec/api/v1/schemas/profiles'
require './spec/api/v1/schemas/rule_results'
require './spec/api/v1/schemas/rules'

module Api
  module V1
    module Schemas
      include Types
      include Errors
      include Metadata
      include Hosts
      include Benchmarks
      include Profiles
      include RuleResults
      include Rules

      SCHEMAS = {
        uuid: UUID,
        relationship: RELATIONSHIP,
        error: ERROR,
        metadata: METADATA,
        host: HOST,
        links: LINKS,
        benchmark: BENCHMARK,
        profile: PROFILE,
        rule_result: RULE_RESULT,
        rule: RULE
      }.freeze
    end
  end
end
