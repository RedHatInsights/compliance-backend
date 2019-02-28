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

  def rule_ids
    test_result.rr.keys
  end

  def rule_objects
    @rule_objects ||= @benchmark.items.select do |_, v|
      v.is_a?(OpenSCAP::Xccdf::Rule)
    end
  end

  def rule_already_saved(rule, profiles)
    found_rule = Rule.find_by(ref_id: rule.id)
    return false if found_rule.blank?

    new_profiles = []
    profiles.each do |profile|
      new_profiles.append(profile) unless found_rule.profiles.include?(profile)
    end

    found_rule.profiles << new_profiles
    found_rule.save
  end

  def save_rules
    save_profiles
    new_profiles = Profile.where(ref_id: profiles.keys)
    rule_objects.each_with_object([]) do |rule, new_rules|
      rule_object = rule[1]
      next if rule_already_saved(rule_object, new_profiles)

      new_rule = Rule.new(profiles: new_profiles).from_oscap_object(rule_object)
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
