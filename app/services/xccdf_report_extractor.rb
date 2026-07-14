# frozen_string_literal: true

# Streams an XCCDF report and extracts only the Benchmark metadata and TestResult subtree
class XccdfReportExtractor
  class ExtractionError < StandardError; end

  def self.extract(xml_string)
    new(xml_string).extract
  end

  def initialize(xml_string)
    @xml = xml_string
  end

  def extract
    benchmark_tag = nil
    benchmark_name = nil
    benchmark_depth = nil
    version_xml = nil
    test_result_xml = nil

    reader = Nokogiri::XML::Reader(@xml)
    reader.each do |node|
      next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT

      if benchmark_depth.nil? && node.local_name == 'Benchmark'
        benchmark_depth = node.depth
        benchmark_name = node.name
        benchmark_tag = build_benchmark_open_tag(node)
        next
      end

      next unless benchmark_depth
      next unless node.depth == benchmark_depth + 1

      case node.local_name
      when 'version'
        version_xml ||= node.outer_xml
      when 'TestResult'
        test_result_xml = node.outer_xml
        break
      end
    end

    validate!(benchmark_tag, version_xml, test_result_xml)
    build_minimal_xml(benchmark_tag, benchmark_name, version_xml, test_result_xml)
  rescue Nokogiri::XML::SyntaxError => e
    raise ExtractionError, "Malformed XML: #{e.message}"
  end

  private

  def build_benchmark_open_tag(node)
    attr_str = node.attributes&.map { |name, value| %(#{name}="#{value}") }&.join(' ')
    attr_str ? "<#{node.name} #{attr_str}>" : "<#{node.name}>"
  end

  def validate!(benchmark_tag, version_xml, test_result_xml)
    raise ExtractionError, 'No <Benchmark> element found in report' unless benchmark_tag
    raise ExtractionError, 'No <version> element found in report' unless version_xml
    raise ExtractionError, 'No <TestResult> element found in report' unless test_result_xml
  end

  def build_minimal_xml(benchmark_tag, benchmark_name, version_xml, test_result_xml)
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n#{benchmark_tag}\n#{version_xml}\n#{test_result_xml}\n</#{benchmark_name}>"
  end
end
