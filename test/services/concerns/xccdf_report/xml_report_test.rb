# frozen_string_literal: true

require 'test_helper'
require 'xccdf_report/xml_report'

class XMLReportTest < ActiveSupport::TestCase
  include XCCDFReport::XMLReport

  setup do
    report_xml(File.read('test/fixtures/files/xccdf_report.xml'))
  end

  test 'report_xml parses the XML report' do
    assert_equal report_xml.class, Nokogiri::XML::Document
  end

  test 'find_namespace' do
    assert_equal find_namespace(report_xml), 'http://checklists.nist.gov/xccdf/1.2'
  end

  test 'report_description' do
    assert_match(/^This guide presents/, report_description)
  end

  test 'report_host' do
    assert_match report_host, 'lenovolobato.lobatolan.home'
  end
end
