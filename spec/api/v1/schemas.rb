# frozen_string_literal: true

require './spec/api/v1/schemas/types'
require './spec/api/v1/schemas/errors'
require './spec/api/v1/schemas/metadata'
require './spec/api/v1/schemas/hosts'
require './spec/api/v1/schemas/benchmarks'
require './spec/api/v1/schemas/business_objectives'
require './spec/api/v1/schemas/profiles'
require './spec/api/v1/schemas/rule_results'
require './spec/api/v1/schemas/rules'
require './spec/api/v1/schemas/status'
require './spec/api/v1/schemas/supported_ssgs'

module Api
  module V1
    module Schemas
      include Types
      include Errors
      include Metadata
      include Hosts
      include Benchmarks
      include BusinessObjectives
      include Profiles
      include RuleResults
      include Rules
      include Status
      include SupportedSggs

      SCHEMAS = {
        uuid: UUID,
        relationship: RELATIONSHIP,
        relationship_collection: RELATIONSHIP_COLLECTION,
        error: ERROR,
        metadata: METADATA,
        host: HOST,
        host_relationships: HOST_RELATIONSHIPS,
        links: LINKS,
        benchmark: BENCHMARK,
        benchmark_relationships: BENCHMARK_RELATIONSHIPS,
        business_objective: BUSINESS_OBJECTIVE,
        business_objective_relationships: BUSINESS_OBJECTIVE_RELATIONSHIPS,
        profile: PROFILE,
        profile_relationships: PROFILE_RELATIONSHIPS,
        rule_result: RULE_RESULT,
        rule_result_relationships: RULE_RESULT_RELATIONSHIPS,
        rule: RULE,
        rule_relationships: RULE_RELATIONSHIPS,
        status: STATUS,
        supported_ssg: SUPPORTED_SSG
      }.freeze
    end
  end
end
