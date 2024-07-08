# frozen_string_literal: true

Dir['./spec/api/v2/schemas/*.rb'].each { |file| require file }

module Api
  module V2
    # :nodoc:
    module Schemas
      include Errors
      include Metadata
      include Policy
      include Profile
      include Report
      include ReportStats
      include Rule
      include RuleGroup
      include RuleResult
      include RuleTree
      include SecurityGuide
      include SupportedProfile
      include System
      include Tailoring
      include TailoringFile
      include TestResult
      include Types
      include ValueDefinition

      SCHEMAS = {
        errors: ERRORS,
        id: UUID,
        links: LINKS,
        metadata: METADATA,
        policy: POLICY,
        policy_update: POLICY_UPDATE,
        profile: PROFILE,
        report: REPORT,
        report_stats: REPORT_STATS,
        rule: RULE,
        rule_group: RULE_GROUP,
        rule_result: RULE_RESULT,
        rule_tree: RULE_TREE,
        security_guide: SECURITY_GUIDE,
        supported_profile: SUPPORTED_PROFILE,
        system: SYSTEM,
        tailoring: TAILORING,
        tailoring_file: TAILORING_FILE,
        test_result: TEST_RESULT,
        value_definition: VALUE_DEFINITION
      }.freeze
    end
  end
end
