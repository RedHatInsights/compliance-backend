# frozen_string_literal: true

require 'openscap'
require 'openscap/source'
require 'openscap/xccdf'
require 'openscap/xccdf/benchmark'
require 'openscap/xccdf/testresult'

# Takes in a path to an XCCDF file, returns all kinds of properties about it
# and saves it in our database
class XCCDFReportParser
  include ::XCCDFReport::XMLReport
  include ::XCCDFReport::Profiles

  def initialize(report_path, account)
    @report_path = report_path
    @account = Account.find_or_create_by(account_number: account)
    @source = ::OpenSCAP::Source.new(report_path)
    @benchmark = ::OpenSCAP::Xccdf::Benchmark.new(@source)
  end

  def test_result
    return @test_result if @test_result.present?

    source = ::OpenSCAP::Source.new(
      content: create_test_result(report_xml).to_xml
    )
    begin
      @test_result = ::OpenSCAP::Xccdf::TestResult.new(source)
    rescue ::OpenSCAP::OpenSCAPError => e
      Rails.logger.error('Error: ', e)
    end
  end

  def report_host
    report_xml.search('target').text
  end

  def inventory_api
    HostInventoryAPI.new(
      @host,
      @account,
      Settings.host_inventory_url
    )
  end

  def save_host
    @host = Host.find_or_initialize_by(
      name: report_host,
      account: @account
    )
    new_profiles = new_profiles
    @host.profiles << new_profiles if new_profiles.present?
    inventory_api.sync
  end

  def score
    test_result.score['urn:xccdf:scoring:default'][:value]
  end

  def rule_ids
    test_result.rr.keys
  end

  def rule_objects
    @rule_objects ||= @benchmark.items.select do |_, v|
      v.is_a?(OpenSCAP::Xccdf::Rule)
    end
  end

  def save_rules
    save_profiles
    rule_objects.each_with_object([]) do |rule, new_rules|
      rule_object = rule[1]
      next if Rule.find_by(ref_id: rule_object.id)

      new_rule = Rule.new(
        profiles: Profile.where(ref_id: profiles.keys)
      ).from_oscap_object(rule_object)
      new_rule.save
      new_rules << new_rule
    end
  end

  def rule_results
    test_result.rr.map { |_, v| v }
  end

  def save_rule_results
    save_rules
    save_host
    rule_results.each_with_object([]) do |rule_result, rule_results|
      rule_results << RuleResult.create(
        host: Host.find_by(name: report_host),
        rule: Rule.find_by(ref_id: rule_result.id),
        result: rule_result.result
      )
    end
  end

  private

  def create_test_result(report_xml)
    test_result_node = report_xml.search('TestResult')
    test_result_doc = Nokogiri::XML::Document.parse(test_result_node.to_xml)
    test_result_doc.root.default_namespace = find_namespace(report_xml)
    test_result_doc.namespace = test_result_doc.root.namespace
    test_result_doc
  end
end
