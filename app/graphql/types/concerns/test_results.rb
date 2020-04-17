# frozen_string_literal: true

module Types
  # Methods related to scoring and results
  module TestResults
    extend ActiveSupport::Concern

    def score(args = {})
      ::Rails.cache.fetch("#{system_id(args)}/#{object.id}/score") do
        latest_test_result_batch(args).then do |latest_test_result|
          if latest_test_result.blank?
            0
          else
            latest_test_result.score
          end
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
      ::Rails.cache.fetch("#{system_id(args)}/#{object.id}/rules_passed") do
        latest_test_result_batch(args).then do |latest_test_result|
          if latest_test_result.blank?
            0
          else
            latest_test_result.rule_results.passed.count
          end
        end
      end
    end

    def rules_failed(args = {})
      ::Rails.cache.fetch("#{system_id(args)}/#{object.id}/rules_failed") do
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
