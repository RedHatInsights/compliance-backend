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
          host_results = latest_test_result&.rule_results
          host_results.present? &&
            latest_test_result.score >= object.compliance_threshold
        end
      end

      def rules_passed(args = {})
        latest_test_result_batch(args).then do |latest_test_result|
          if latest_test_result.blank?
            0
          else
            latest_test_result.rule_results.passed.count
          end
        end
      end

      def rules_failed(args = {})
        latest_test_result_batch(args).then do |latest_test_result|
          if latest_test_result.blank?
            0
          else
            latest_test_result.rule_results.failed.count
          end
        end
      end
    end
  end
end
