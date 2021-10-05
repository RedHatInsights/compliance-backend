# frozen_string_literal: true

unless defined? Rails
  require File.expand_path('../../config/environment', __dir__)
end

# when /metrics is called. This runs directly on prometheus_exporter.
class EngineeringCollector < PrometheusExporter::Server::TypeCollector
  LRU_DURATION = 1.hour

  def initialize
    @cache = ActiveSupport::Cache::MemoryStore.new(expires_in: LRU_DURATION)
    @dangling_accounts = PrometheusExporter::Metric::Gauge.new(
      'dangling_accounts', 'Accounts without hosts'
    )
    @dangling_test_results = PrometheusExporter::Metric::Gauge.new(
      'dangling_test_results', 'TestResults without hosts'
    )
    @dangling_rule_results = PrometheusExporter::Metric::Gauge.new(
      'dangling_rule_results', 'RuleResults without hosts'
    )
    @dangling_policy_hosts = PrometheusExporter::Metric::Gauge.new(
      'dangling_policy_hosts', 'PolicyHosts without hosts'
    )
  end

  def type
    'engineering'
  end

  def dangling(model)
    model.where.not(host_id: Host.with_policies_or_test_results.select(:id))
  end

  def dangling_accounts
    Account.where.not(account_number: Host.with_policies_or_test_results
                                          .select(:account).distinct)
  end

  def collect
    @dangling_accounts.observe(dangling_accounts.count)
    @dangling_test_results.observe(dangling(TestResult).count)
    @dangling_rule_results.observe(dangling(RuleResult).count)
    @dangling_policy_hosts.observe(dangling(PolicyHost).count)
  end

  def metrics
    @cache.fetch('metrics') do
      collect

      [
        @dangling_accounts,
        @dangling_test_results,
        @dangling_rule_results,
        @dangling_policy_hosts
      ]
    end
  end
end
