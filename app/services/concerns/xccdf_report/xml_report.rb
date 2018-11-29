# frozen_string_literal: true

module XCCDFReport
  # Methods related with parsing directly the XML from the Report
  # as opposed to using the OpenSCAP APIs
  module XMLReport
    extend ActiveSupport::Concern

    included do
      def report_host
        report_xml.search('target').text
      end

      def report_description
        report_xml.search('description').first.text
      end

      def find_namespace(report_xml)
        report_xml.namespaces['xmlns']
      end

      def report_xml
        @report_xml ||= File.open(@report_path) { |f| Nokogiri::XML(f) }
      end
    end
  end
end
