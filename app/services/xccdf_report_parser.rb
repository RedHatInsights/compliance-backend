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
    file = Tempfile.new(SecureRandom.uuid)
    file.write(report_contents)
    @report_path = file.path
    @b64_identity = b64_identity
    @account = Account.find_or_create_by(account_number: account)
    @source = ::OpenSCAP::Source.new(@report_path)
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
      Sidekiq.logger.error('Error: ', e)
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

  def rule_results
    test_result.rr.map { |_, v| v }
  end

  def save_all
    Host.transaction do
      save_profiles
      save_rules
      save_host
      save_rule_results
    end
  end

  def save_rule_results
    host_object = Host.find_by(name: report_host)
    rules = Rule.where(ref_id: rule_results.map(&:id))
    results = rule_results.map(&:result)
    RuleResult.import(
      rules.zip(results).each_with_object([]) do |rule_result, rule_results|
        rule_results << RuleResult.new(host: host_object, rule: rule_result[0],
                                       result: rule_result[1])
      end
    )
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
