# frozen_string_literal: true

module Xccdf
  # Utility methods for saving openscap_parser data to the DB
  module Util
    extend ActiveSupport::Concern

    included do
      include ::Xccdf::SecurityGuides
      include ::Xccdf::Profiles
      include ::Xccdf::Rules
      include ::Xccdf::Fixes
      include ::Xccdf::RuleGroups
      include ::Xccdf::ValueDefinitions
      include ::Xccdf::ProfileRules
      include ::Xccdf::ProfileOsMinorVersions
      include ::Xccdf::RuleGroupRelationships
      include ::Xccdf::Hosts
      include ::Xccdf::RuleResults
      include ::Xccdf::TestResult

      # rubocop:disable Metrics/MethodLength
      def save_all_security_guide_info
        return if security_guide_contents_equal_to_op?

        save_security_guide
        save_value_definitions
        save_profiles
        save_rule_groups
        save_rules
        save_fixes
        save_rule_group_relationships
        save_profile_rules
        save_profile_os_minor_versions
      end
      # rubocop:enable Metrics/MethodLength

      def save_all_test_result_info
        save_host_profile
        save_test_result
        save_rule_results
        invalidate_cache
      end

      def set_openscap_parser_data
        @op_security_guide = @test_result_file.benchmark
        @op_test_result = @test_result_file.test_result
        @op_rule_groups = @op_security_guide.groups
        @op_profiles = @op_security_guide.profiles
        @op_value_definitions = @op_security_guide.values
        @op_rules = @op_security_guide.rules
        @op_rule_results = @op_test_result.rule_results
      end

      private

      def invalidate_cache
        Rails.cache.delete("#{@new_host_profile&.id}/#{@host&.id}/results")
        puts "\n\u001b[31;1m◉\u001b[0m app/services/concerns/xccdf/util.rb"
        puts "@host_profile: #{@host_profile}"
        puts "-" * 40
        @host_profile.rules.each do |rule|
          Rails.cache.delete("#{rule.id}/#{@host&.id}/compliant")
        end
      end
    end
  end
end
