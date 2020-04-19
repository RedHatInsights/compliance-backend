# frozen_string_literal: true

module Types
  # Methods related to scoring and results
  module TestResults
    extend ActiveSupport::Concern

    def cached_score(profile, host)
      ::Rails.cache.read(profile: profile, host: host, attribute: 'score')
    end

    def cached_rules_passed(profile, host)
      ::Rails.cache.read(
        profile: profile, host: host, attribute: 'rules_passed'
      )
    end

    def cached_rules_failed(profile, host)
      ::Rails.cache.read(
        profile: profile, host: host, attribute: 'rules_failed'
      )
    end

    def score(args = {})
      return cached_score if cached_score(object.id, system_id(args))
      latest_test_result_batch(args).then do |latest_test_result|
        if latest_test_result.blank?
          0
        else
          latest_test_result.score
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
      return cached_rules_passed(object.id, system_id(args)) if cached_rules_passed(object.id, system_id(args))
      latest_test_result_batch(args).then do |latest_test_result|
        if latest_test_result.blank?
          0
        else
          latest_test_result.rule_results.passed.count
        end
      end
    end

    def rules_failed(args = {})
      return cached_rules_failed(object.id, system_id(args)) if cached_rules_failed(object.id, system_id(args))
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
