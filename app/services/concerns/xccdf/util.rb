# frozen_string_literal: true

module Xccdf
  # Utility methods for saving openscap_parser data to the DB
  module Util
    extend ActiveSupport::Concern

    included do
      include ::Xccdf::Benchmarks
      include ::Xccdf::Profiles
      include ::Xccdf::Rules
      include ::Xccdf::ProfileRules
      include ::Xccdf::RuleReferences
      include ::Xccdf::RuleReferencesRules
      include ::Xccdf::Hosts
      include ::Xccdf::RuleResults

      def save_all_benchmark_info
        save_benchmark
        save_profiles
        save_rules
        save_profile_rules
        save_rule_references
        save_rule_references_rules
      end

      def save_all_test_result_info
        save_host
        @host_profile = save_profile_host
        save_rule_results
        invalidate_cache
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
