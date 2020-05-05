# frozen_string_literal: true

unless defined? Rails
  require File.expand_path('../../config/environment', __dir__)
end

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
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
    @total_policies = PrometheusExporter::Metric::Gauge.new(
      'total_policies', 'Policies (non-canonical)'
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
    @total_systems = PrometheusExporter::Metric::Gauge.new(
      'total_systems', 'Systems'
    )
    @client_systems = PrometheusExporter::Metric::Gauge.new(
      'client_systems', 'Systems from clients (excludes Red Hat)'
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
      Host.where(
        account_id: client_accounts.select(:id)
      ).select(:account_id).distinct.count
    )
    @total_policies.observe Profile.where.not(parent_profile_id: nil).count
    @client_policies.observe(
      Profile.where(account_id: client_accounts.select(:id)).count
    )
    @total_systems.observe Host.count
    @client_systems.observe(
      Host.where(account_id: client_accounts.select(:id)).count
    )
  end

  def metrics
    collect
    [
      @total_accounts,
      @client_accounts,
      @client_accounts_with_hosts,
      @total_policies,
      @client_policies,
      @total_systems,
      @client_systems
    ]
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
