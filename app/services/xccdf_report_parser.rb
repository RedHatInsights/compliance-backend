# frozen_string_literal: true

require 'openscap'
require 'openscap/source'
require 'openscap/xccdf'
require 'openscap/xccdf/benchmark'
require 'openscap/xccdf/testresult'

# Takes in a path to an XCCDF file, returns all kinds of properties about it
# and saves it in our database
class XCCDFReportParser
  def initialize(report_path)
    @report_path = report_path
    @source = ::OpenSCAP::Source.new(report_path)
    @benchmark = ::OpenSCAP::Xccdf::Benchmark.new(@source)
  end

  def profiles
    @benchmark.profiles.map { |id, oscap_profile| [id, oscap_profile.title] }
  end
end
