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
  include ::XCCDFReport::Rules

  attr_reader :report_path

  def initialize(report_contents, account, b64_identity)
    report_xml(report_contents)
    @b64_identity = b64_identity
    @account = Account.find_or_create_by(account_number: account)
    @source = ::OpenSCAP::Source.new(content: report_contents,
                                     length: report_contents.bytes.count)
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
      Sidekiq.logger.error("Error: #{e}")
    end
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
      name: report_host,
      account_id: @account.id
    )
    new_profiles = host_new_profiles
    @host.profiles << new_profiles if new_profiles.present?
    inventory_api.sync
  end

  def score
    test_result.score['urn:xccdf:scoring:default'][:value]
  end

  def start_time
    @start_time ||= DateTime.parse(test_result_node['start-time']).in_time_zone
  end

  def end_time
    @end_time ||= DateTime.parse(test_result_node['end-time']).in_time_zone
  end

  def rule_results
    @rule_results ||= test_result.rr.values
  end

  def save_all
    Host.transaction do
      save_profiles
      save_rules
      save_host
      rules_already_saved.each do |rule|
        Rails.cache.delete("#{rule.id}/#{@host.id}/compliant")
      end
      save_rule_results
    end
  end

  def save_rule_results
    results = rule_results.map(&:result)
    RuleResult.import(
      rule_results_rule_ids.zip(results)
      .each_with_object([]) do |rule_result, rule_results|
        rule_results << RuleResult.new(host: host_id, rule_id: rule_result[0],
                                       result: rule_result[1],
                                       start_time: start_time,
                                       end_time: end_time)
      end
    )
  end

  private

  def test_result_node
    test_result = report_xml.search('TestResult')
    test_result.first if test_result.one?
  end

  def rule_results_rule_ids
    @rule_results_rule_ids ||= Rule.select(:id).where(
      ref_id: rule_results.map(&:id)
    ).pluck(:id)
  end

  def host_id
    @host_id ||= Host.select(:id).find_by(name: report_host)
  end

  def create_test_result(report_xml)
    test_result_doc = Nokogiri::XML::Document.parse(test_result_node.to_xml)
    test_result_doc.root.default_namespace = find_namespace(report_xml)
    test_result_doc.namespace = test_result_doc.root.namespace
    test_result_doc
  end
end
