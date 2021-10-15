# frozen_string_literal: true

unless defined? Rails
  require File.expand_path('../../config/environment', __dir__)
end

# Collects stats relevent for the business from the database
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
    @total_policies_by_account = PrometheusExporter::Metric::Gauge.new(
      'total_policies_by_account', 'Policies by account'
    )
    @client_policies_by_account = PrometheusExporter::Metric::Gauge.new(
      'client_policies_by_account', 'Policies by account (exludes Red Hat)'
    )
    @total_policies_by_host = PrometheusExporter::Metric::Gauge.new(
      'total_policies_by_host', 'Policies by host'
    )
    @client_policies_by_host = PrometheusExporter::Metric::Gauge.new(
      'client_policies_by_host', 'Policies by host (exludes Red Hat)'
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
    @total_policies_by_os_major = PrometheusExporter::Metric::Gauge.new(
      'total_policies_by_os_major', 'Policies by OS major version'
    )
    @client_policies_by_os_major = PrometheusExporter::Metric::Gauge.new(
      'client_policies_by_os_major', 'Policies by OS major version (excludes Red Hat)'
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
      'client_systems_by_os', 'Systems by OS version (excludes Red Hat)'
    )
    @total_systems_by_policy = PrometheusExporter::Metric::Gauge.new(
      'total_systems_by_policy', 'Systems by assigned policies'
    )
    @total_systems_by_policy = PrometheusExporter::Metric::Gauge.new(
      'total_systems_by_policy', 'Systems by assigned policies (excludes Red Hat)'
    )
  end

  def type
    'business'
  end

  def collect
    @total_accounts.observe Account.count
    client_accounts = Account.where(is_internal: [nil, false])
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

    Policy.joins(:profiles)
          .select(:account_id, "profiles.ref_id").distinct
          .group(:ref_id)
          .count(:account_id).each do |ref_id, count|
      @total_policies_by_account.observe(count, ref_id: ref_id)
    end

    Policy.where(account_id: client_accounts.select(:id))
          .joins(:profiles)
          .select(:account_id, "profiles.ref_id").distinct
          .group(:ref_id)
          .count(:account_id).each do |ref_id, count|
      @client_policies_by_account.observe(count, ref_id: ref_id)
    end

    Policy.joins(:policy_hosts).joins(:profiles)
          .select('policy_hosts.host_id', 'profiles.ref_id').distinct
          .group(:ref_id)
          .count(:host_id).each do |ref_id, count|
      @total_policies_by_host.observe(count, ref_id: ref_id)
    end

    Policy.where(account_id: client_accounts.pluck(:id))
          .joins(:policy_hosts).joins(:profiles)
          .select('policy_hosts.host_id', 'profiles.ref_id').distinct
          .group(:ref_id)
          .count(:host_id).each do |ref_id, count|
      @client_policies_by_host.observe(count, ref_id: ref_id)
    end

    @total_systems.observe Host.with_policies_or_test_results.count
    @client_systems.observe(
      Host.with_policies_or_test_results
          .where(account: client_accounts.select(:account_number)).count
    )

    Policy.joins(:benchmarks).distinct.group('benchmarks.ref_id').count.each do |ref_id, cnt|
      @total_policies_by_os_major.observe(cnt, version: ref_id[/(?<=RHEL-)\d/])
    end

    Policy.where(account_id: client_accounts.select(:id))
          .joins(:benchmarks).distinct.group('benchmarks.ref_id').count.each do |ref_id, cnt|
      @client_policies_by_os_major.observe(cnt, version: ref_id[/(?<=RHEL-)\d/])
    end

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
      @total_policies_by_account,
      @client_policies_by_account,
      @total_policies_by_host,
      @client_policies_by_host,
      @total_policies_by_os_major,
      @client_policies_by_os_major,
      @total_50plus_policies,
      @client_50plus_policies,
      @total_systems,
      @client_systems,
      @total_systems_by_os,
      @client_systems_by_os
    ]
  end
end
