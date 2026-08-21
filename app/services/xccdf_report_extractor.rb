# frozen_string_literal: true

require 'cgi'

# Streams an XCCDF report and extracts only the Benchmark metadata and TestResult subtree
class XccdfReportExtractor
  class ExtractionError < StandardError; end

  # Quote-aware match for the Benchmark start tag. Used instead of
  # Reader#attribute_hash / #namespaces, which call xmlTextReaderExpand and
  # materialize the entire Benchmark subtree (the rest of the report).
  BENCHMARK_OPEN_TAG = /
    <((?:[A-Za-z_][\w.-]*:)?Benchmark)
    \b
    (?:[^>"']|"[^"]*"|'[^']*')*
    >
  /x

  FALLBACK_ATTRS = %w[xmlns xmlns:xsi id resolved style xml:lang].freeze

  def self.extract(xml_string)
    new(xml_string).extract
  end

  def initialize(xml_string)
    @xml = xml_string
  end

  def extract
    fragments = scan_report
    validate!(fragments)
    build_minimal_xml(fragments)
  rescue Nokogiri::XML::SyntaxError => e
    raise ExtractionError, "Malformed XML: #{e.message}"
  end

  private

  def scan_report
    fragments = empty_fragments

    Nokogiri::XML::Reader(@xml).each do |node|
      next unless element?(node)

      process_node(fragments, node)
      break if fragments[:test_result_xml]
    end

    fragments
  end

  def empty_fragments
    {
      benchmark_tag: nil,
      benchmark_name: nil,
      benchmark_depth: nil,
      version_xml: nil,
      test_result_xml: nil
    }
  end

  def element?(node)
    node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
  end

  def process_node(fragments, node)
    if fragments[:benchmark_depth].nil?
      capture_benchmark!(fragments, node)
      return
    end

    return unless node.depth == fragments[:benchmark_depth] + 1

    capture_child!(fragments, node)
  end

  def capture_benchmark!(fragments, node)
    return unless node.local_name == 'Benchmark'

    fragments[:benchmark_depth] = node.depth
    fragments[:benchmark_name] = node.name
    fragments[:benchmark_tag] = raw_benchmark_open_tag || fallback_open_tag(node)
  end

  def capture_child!(fragments, node)
    case node.local_name
    when 'version'
      fragments[:version_xml] ||= node.outer_xml
    when 'TestResult'
      fragments[:test_result_xml] = node.outer_xml
    end
  end

  def raw_benchmark_open_tag
    @xml[BENCHMARK_OPEN_TAG]
  end

  # Reader#attribute / #namespace_uri do not expand the subtree.
  def fallback_open_tag(node)
    attr_str = FALLBACK_ATTRS.filter_map do |name|
      value = node.attribute(name)
      %(#{name}="#{escape_xml_attribute(value)}") if value
    end.join(' ')

    attr_str.empty? ? "<#{node.name}>" : "<#{node.name} #{attr_str}>"
  end

  def escape_xml_attribute(value)
    CGI.escapeHTML(value.to_s)
  end

  def validate!(fragments)
    raise ExtractionError, 'No <Benchmark> element found in report' unless fragments[:benchmark_tag]
    raise ExtractionError, 'No <version> element found in report' unless fragments[:version_xml]
    raise ExtractionError, 'No <TestResult> element found in report' unless fragments[:test_result_xml]
  end

  def build_minimal_xml(fragments)
    <<~XML.chomp
      <?xml version="1.0" encoding="UTF-8"?>
      #{fragments[:benchmark_tag]}
      #{fragments[:version_xml]}
      #{fragments[:test_result_xml]}
      </#{fragments[:benchmark_name]}>
    XML
  end
end
