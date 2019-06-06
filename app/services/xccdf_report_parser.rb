# frozen_string_literal: true

# Mimics openscap-ruby RuleResult interface
class RuleResultOscapObject
  attr_accessor :id, :result, :ident
end

# Takes in a path to an XCCDF file, returns all kinds of properties about it
# and saves it in our database
class XCCDFReportParser
  include ::XCCDFReport::XMLReport
  include ::XCCDFReport::Profiles
  include ::XCCDFReport::Rules

  attr_reader :report_path

  def initialize(report_contents, message)
    report_xml(report_contents)
    @b64_identity = message['b64_identity']
    @account = Account.find_or_create_by(account_number: message['account'])
    @metadata = message['metadata']
    @host_inventory_id = message['id']
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

  def score
    test_result_node.search('score').text.to_f
  end

  def start_time
    @start_time ||= DateTime.parse(test_result_node['start-time']).in_time_zone
  end

  def end_time
    @end_time ||= DateTime.parse(test_result_node['end-time']).in_time_zone
  end

  def rule_results
    @rule_results ||= test_result_node.css('rule-result').map do |rr|
      rule_result_oscap = RuleResultOscapObject.new
      rule_result_oscap.id = rr['idref']
      rule_result_oscap.result = rr.at_css('result').text
      rule_result_oscap
    end
  end

  def save_all
    Host.transaction do
      save_profiles
      save_rule_references
      save_rules
      save_host
      rules_already_saved.each do |rule|
        Rails.cache.delete("#{rule.id}/#{@host.id}/compliant")
      end
      Rails.cache.delete("#{@host.id}/failed_rule_objects_result")
      save_rule_results
    end
  end

  def save_rule_results
    results = rule_results.map(&:result)
    RuleResult.import!(
      rule_results_rule_ids.zip(results)
      .each_with_object([]) do |rule_result, rule_results|
        rule_results << RuleResult.new(host: @host, rule_id: rule_result[0],
                                       result: rule_result[1],
                                       start_time: start_time,
                                       end_time: end_time)
      end
    )
  end

  private

  def test_result_node
    @test_result_node ||= @report_xml.at_css('TestResult')
  end

  def rule_results_rule_ids
    @rule_results_rule_ids ||= Rule.select(:id).where(
      ref_id: rule_results.map(&:id)
    ).pluck(:id)
  end

  def create_test_result(report_xml)
    test_result_doc = Nokogiri::XML::Document.parse(test_result_node.to_xml)
    test_result_doc.root.default_namespace = find_namespace(report_xml)
    test_result_doc.namespace = test_result_doc.root.namespace
    test_result_doc
  end
end
