# frozen_string_literal: true

module Types
  module Concerns
    # Methods related to scoring and results
    module TestResults
      extend ActiveSupport::Concern

      def score(args = {})
        latest_test_result_batch(args).then do |latest_test_result|
          if latest_test_result.blank?
            0
          else
            latest_test_result.score
          end
        end
      end

      def supported(args = {})
        latest_test_result_batch(args).then do |latest_test_result|
          if latest_test_result.blank?
            false
          else
            latest_test_result.supported
          end
        end
      end

      def compliant(args = {})
        latest_test_result_batch(args).then do |latest_test_result|
          if latest_test_result.blank?
            false
          else
            CollectionLoader.for(::TestResult, :has_rule_results).load(latest_test_result).then do |has|
              has.present? &&
                latest_test_result.score >= object.compliance_threshold
            end
          end
        end
      end

      def rules_passed(args = {})
        rules_count(args, RuleResult::PASSED)
      end

      def rules_failed(args = {})
        rules_count(args, RuleResult::FAILED)
      end

      def rules_count(args, subset)
        latest_test_result_batch(args).then do |latest_test_result|
          if latest_test_result.blank?
            0
          else
            CollectionLoader.for(::TestResult, :counters).load(latest_test_result).then do |counters|
              counters.select { |counter| subset.include?(counter.result) }.sum { |item| item&.count.to_i }
            end
          end
        end
      end
    end
  end
end
