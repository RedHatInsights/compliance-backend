# frozen_string_literal: true

require 'rails_helper'

describe ReportsTarReader do
  describe '#reports' do
    it 'extracts all reports from a standard archive' do
      reports = described_class.new(file_fixture('insights-archive.tar.gz').open).reports

      expect(reports.length).to eq(3)
    end

    it 'extracts reports whose filename exceeds the tar header limit' do
      reports = described_class.new(file_fixture('insights-archive-long.tar.gz').open).reports

      expect(reports.length).to eq(1)
    end

    it 'omits entries where openscap_results appears outside the filename' do
      reports = described_class.new(file_fixture('insights-archive-prefixed.tar.gz').open).reports

      expect(reports.length).to eq(0)
    end
  end
end
