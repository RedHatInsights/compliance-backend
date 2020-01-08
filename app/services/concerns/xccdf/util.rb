# frozen_string_literal: true

module Xccdf
  # Utility methods for saving openscap_parser data to the DB
  module Util
    extend ActiveSupport::Concern

    included do
      include ::Xccdf::Benchmarks
      include ::Xccdf::Profiles
      include ::Xccdf::Rules
      include ::Xccdf::RuleIdentifiers
      include ::Xccdf::ProfileRules
      include ::Xccdf::RuleReferences
      include ::Xccdf::RuleReferencesRules
      include ::Xccdf::Hosts
      include ::Xccdf::RuleResults
      include ::Xccdf::TestResult

      def save_all_benchmark_info
        return if benchmark_saved?

        save_benchmark
        save_profiles
        save_rules
        save_rule_identifiers
        save_profile_rules
        save_rule_references
        save_rule_references_rules
      end

      def save_all_test_result_info
        save_host
        save_profile_host
        save_test_result
        save_rule_results
        associate_rules_from_rule_results
        invalidate_cache
      end

      def set_openscap_parser_data
        @op_benchmark = @test_result_file.benchmark
        @op_test_result = @test_result_file.test_result
        @op_profiles = @op_benchmark.profiles
        @op_rules = @op_benchmark.rules
        @op_rule_references =
          @op_benchmark.rule_references.reject { |rr| rr.label.empty? }
        @op_rule_results = @op_test_result.rule_results
      end

      private

      def invalidate_cache
        Rails.cache.delete("#{@host&.id}/failed_rule_objects_result")
        Rails.cache.delete("#{@new_host_profile&.id}/#{@host&.id}/results")
        @host_profile.rules.each do |rule|
          Rails.cache.delete("#{rule.id}/#{@host&.id}/compliant")
        end
      end
    end
  end
end
