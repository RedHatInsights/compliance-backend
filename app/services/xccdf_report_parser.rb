# frozen_string_literal: true

# Mimics openscap-ruby RuleResult interface
class RuleResultOscapObject
  attr_accessor :id, :result, :ident
end

# Takes in a path to an XCCDF file, returns all kinds of properties about it
# and saves it in our database
class XCCDFReportParser
  include ::XCCDFReport::Profiles
  include ::XCCDFReport::Rules

  attr_reader :report_path, :oscap_parser

  def initialize(report_contents, message)
    @b64_identity = message['b64_identity']
    @account = Account.find_or_create_by(account_number: message['account'])
    @metadata = message['metadata']
    @host_inventory_id = message['id']
    @oscap_parser = OpenscapParser::Base.new(report_contents)
  end

  def inventory_api
    HostInventoryAPI.new(
      @host,
      @account,
      Settings.host_inventory_url,
      @b64_identity
    )
  end

  def save_host
    @host = Host.find_or_initialize_by(
      id: @host_inventory_id,
      name: report_host,
      account_id: @account.id
    )
    new_profiles = host_new_profiles
    @host.profiles << new_profiles if new_profiles.present?
    inventory_api.sync
  end

  def report_host
    @metadata&.dig('fqdn') || @oscap_parser.host
  end

  def save_all
    Host.transaction do
      save_profiles
      save_rule_references
      save_rules
      save_host
      invalidate_cache
      save_rule_results
    end
  end

  def save_rule_results
    RuleResult.import!(
      @oscap_parser.rule_results.each_with_object([]) do |rule_result, rule_results|
        rule_results << RuleResult.new(
          host: @host,
          rule_id: rule_results_rule_ids[rule_result.id],
          result: rule_result.result,
          start_time: @oscap_parser.start_time.in_time_zone,
          end_time: @oscap_parser.end_time.in_time_zone
        )
      end
    )
  end

  private

  def invalidate_cache
    rules_already_saved.each do |rule|
      Rails.cache.delete("#{rule.id}/#{@host.id}/compliant")
    end
    Rails.cache.delete("#{@host.id}/failed_rule_objects_result")
  end

  def rule_results_rule_ids
    @rule_results_rule_ids ||= Rule.where(
      ref_id: @oscap_parser.rule_results.map(&:id)
    ).pluck(:ref_id, :id).to_h
  end
end
