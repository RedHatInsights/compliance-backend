# frozen_string_literal: true

unless defined? Rails
  require File.expand_path('../../config/environment', __dir__)
end

# Collects stats relevent for the business from the database
# when /metrics is called. This runs directly on prometheus_exporter.
class BusinessCollector < PrometheusExporter::Server::TypeCollector
  def initialize
    @total_accounts = PrometheusExporter::Metric::Gauge.new(
      'total_accounts', 'Total accounts'
    )
    @client_accounts = PrometheusExporter::Metric::Gauge.new(
      'client_accounts', 'Client accounts (excludes Red Hat)'
    )
    @client_accounts_with_hosts = PrometheusExporter::Metric::Gauge.new(
      'client_accounts_with_hosts',
      'Client accounts with 1 or more hosts (excludes Red Hat)'
    )
    @total_accounts_with_50plus_hosts_per_policy = PrometheusExporter::Metric::Gauge.new(
      'total_accounts_with_50plus_hosts_per_policy',
      'Total accounts with 1 policy or more having 50 or more hosts'
    )
    @client_accounts_with_50plus_hosts_per_policy = PrometheusExporter::Metric::Gauge.new(
      'client_accounts_with_50plus_hosts_per_policy',
      'Client accounts with 1 policy or more having 50 or more hosts (excludes Red Hat)'
    )
    @total_policies = PrometheusExporter::Metric::Gauge.new(
      'total_policies', 'Policies'
    )
    @external_policies = PrometheusExporter::Metric::Gauge.new(
      'external_policies', 'External policies (non-canonical)'
    )
    @internal_policies = PrometheusExporter::Metric::Gauge.new(
      'internal_policies', 'Internal policies (non-canonical)'
    )
    @client_policies = PrometheusExporter::Metric::Gauge.new(
      'client_policies', 'Policies from clients (excludes Red Hat)'
    )
    @total_50plus_policies = PrometheusExporter::Metric::Gauge.new(
      'total_50plus_policies', 'Policies having 50 or more hosts'
    )
    @client_50plus_policies = PrometheusExporter::Metric::Gauge.new(
      'client_50plus_policies', 'Policies from clients having 50 or more hosts (excludes Red Hat)'
    )
    @total_systems = PrometheusExporter::Metric::Gauge.new(
      'total_systems', 'Systems'
    )
    @client_systems = PrometheusExporter::Metric::Gauge.new(
      'client_systems', 'Systems from clients (excludes Red Hat)'
    )
    @total_systems_by_os = PrometheusExporter::Metric::Gauge.new(
      'total_systems_by_os', 'Systems by OS version'
    )
    @client_systems_by_os = PrometheusExporter::Metric::Gauge.new(
      'client_systems_by_os', 'Systems by OS version (excluded Red Hat)'
    )
  end

  def type
    'business'
  end

  def collect
    @total_accounts.observe Account.count
    client_accounts = Account.distinct.where(
      id: User.select(:account_id).where.not('email LIKE ?', '%redhat%')
    )
    @client_accounts.observe client_accounts.count
    @client_accounts_with_hosts.observe(
      Host.with_policies_or_test_results.where(
        account: client_accounts.select(:account_number)
      ).select(:account).distinct.count
    )
    @total_policies.observe Policy.count
    @client_policies.observe(
      Policy.where(account_id: client_accounts.select(:id)).count
    )
    @total_systems.observe Host.with_policies_or_test_results.count
    @client_systems.observe(
      Host.with_policies_or_test_results
          .where(account: client_accounts.select(:account_number)).count
    )

    Host.with_policies_or_test_results.select(
      "COUNT(id), concat(
        #{Host::OS_MAJOR_VERSION},
        '.',
        #{Host::OS_MINOR_VERSION}
      ) as version"
    ).group('version').map(&:attributes).each do |item|
      @total_systems_by_os.observe(item['count'], version: item['version'])
    end

    Host.with_policies_or_test_results.where(
      account: client_accounts.select(:account_number)
    ).select(
      "COUNT(id), concat(
        #{Host::OS_MAJOR_VERSION},
        '.',
        #{Host::OS_MINOR_VERSION}
      ) as version"
    ).group('version').map(&:attributes).each do |item|
      @client_systems_by_os.observe(item['count'], version: item['version'])
    end

    policies_50plus_hosts = PolicyHost.joins(:policy)
                                      .select('policies.account_id')
                                      .group(:policy_id, 'policies.account_id')
                                      .having('COUNT(policy_hosts.host_id) >= 50')

    @total_accounts_with_50plus_hosts_per_policy.observe(
      Account.where(id: policies_50plus_hosts).count(:account_number)
    )

    @client_accounts_with_50plus_hosts_per_policy.observe(
      client_accounts.where(id: policies_50plus_hosts).count(:account_number)
    )

    @total_50plus_policies.observe(policies_50plus_hosts.count.size)
    @client_50plus_policies.observe(
      policies_50plus_hosts.where('policies.account_id' => client_accounts.select(:id)).count.size
    )
  end

  def metrics
    collect
    [
      @total_accounts,
      @client_accounts,
      @client_accounts_with_hosts,
      @total_accounts_with_50plus_hosts_per_policy,
      @client_accounts_with_50plus_hosts_per_policy,
      @total_policies,
      @client_policies,
      @total_50plus_policies,
      @client_50plus_policies,
      @total_systems,
      @client_systems,
      @total_systems_by_os,
      @client_systems_by_os
    ]
  end
end
