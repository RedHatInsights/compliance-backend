# frozen_string_literal: true

require 'rails_helper'

describe XccdfReportExtractor do
  let(:full_xml) { file_fixture('xccdf_report.xml').read }

  describe '.extract' do
    subject(:minimal_xml) { described_class.extract(full_xml) }

    it 'produces a significantly smaller document' do
      expect(minimal_xml.length).to be < full_xml.length / 4
    end

    it 'preserves the Benchmark id attribute' do
      parsed = OpenscapParser::TestResultFile.new(minimal_xml)
      expect(parsed.benchmark.id).to eq('xccdf_org.ssgproject.content_benchmark_RHEL-8')
    end

    it 'preserves the Benchmark version' do
      parsed = OpenscapParser::TestResultFile.new(minimal_xml)
      expect(parsed.benchmark.version).to eq('0.1.40')
    end

    it 'preserves the TestResult profile id' do
      parsed = OpenscapParser::TestResultFile.new(minimal_xml)
      expect(parsed.test_result.profile_id).to eq('xccdf_org.ssgproject.content_profile_standard')
    end

    it 'preserves all rule results' do
      parsed = OpenscapParser::TestResultFile.new(minimal_xml)
      expect(parsed.test_result.rule_results.count).to eq(367)
    end

    it 'returns empty arrays for unused benchmark children' do
      parsed = OpenscapParser::TestResultFile.new(minimal_xml)
      expect(parsed.benchmark.groups).to eq([])
      expect(parsed.benchmark.profiles).to eq([])
      expect(parsed.benchmark.rules).to eq([])
      expect(parsed.benchmark.values).to eq([])
    end

    it 'produces a result that matches a full parse on all used fields' do
      full_parsed = OpenscapParser::TestResultFile.new(full_xml)
      mini_parsed = OpenscapParser::TestResultFile.new(minimal_xml)

      expect(mini_parsed.benchmark.id).to eq(full_parsed.benchmark.id)
      expect(mini_parsed.benchmark.version).to eq(full_parsed.benchmark.version)
      expect(mini_parsed.test_result.profile_id).to eq(full_parsed.test_result.profile_id)
      expect(mini_parsed.test_result.score).to eq(full_parsed.test_result.score)
      expect(mini_parsed.test_result.start_time).to eq(full_parsed.test_result.start_time)
      expect(mini_parsed.test_result.end_time).to eq(full_parsed.test_result.end_time)
      expect(mini_parsed.test_result.rule_results.count).to eq(full_parsed.test_result.rule_results.count)
    end

    context 'with the wrong_xccdf_report fixture' do
      let(:full_xml) { file_fixture('wrong_xccdf_report.xml').read }

      it 'extracts successfully' do
        expect { minimal_xml }.not_to raise_error
      end

      it 'preserves the Benchmark id' do
        parsed = OpenscapParser::TestResultFile.new(minimal_xml)
        expect(parsed.benchmark.id).to be_present
      end
    end

    context 'when Benchmark element is missing' do
      let(:full_xml) { '<not-a-benchmark/>' }

      it 'raises ExtractionError' do
        expect { minimal_xml }.to raise_error(
          described_class::ExtractionError, /No <Benchmark> element/
        )
      end
    end

    context 'when TestResult element is missing' do
      let(:benchmark_id) { Faker::Alphanumeric.alphanumeric(number: 10) }
      let(:full_xml) do
        %(<Benchmark id="#{benchmark_id}"><version>#{Faker::App.semantic_version}</version></Benchmark>)
      end

      it 'raises ExtractionError' do
        expect { minimal_xml }.to raise_error(
          described_class::ExtractionError, /No <TestResult> element/
        )
      end
    end

    context 'when version element is missing' do
      let(:benchmark_id) { Faker::Alphanumeric.alphanumeric(number: 10) }
      let(:full_xml) do
        %(<Benchmark id="#{benchmark_id}"><TestResult id="#{Faker::Internet.uuid}"><score>50</score></TestResult></Benchmark>)
      end

      it 'raises ExtractionError' do
        expect { minimal_xml }.to raise_error(
          described_class::ExtractionError, /No <version> element/
        )
      end
    end

    context 'when XML is malformed' do
      let(:full_xml) { '<Benchmark><truncated' }

      it 'raises ExtractionError' do
        expect { minimal_xml }.to raise_error(
          described_class::ExtractionError, /Malformed XML/
        )
      end
    end

    it 'is idempotent on already-extracted XML' do
      first_pass = described_class.extract(full_xml)
      second_pass = described_class.extract(first_pass)

      parsed1 = OpenscapParser::TestResultFile.new(first_pass)
      parsed2 = OpenscapParser::TestResultFile.new(second_pass)

      expect(parsed2.benchmark.id).to eq(parsed1.benchmark.id)
      expect(parsed2.benchmark.version).to eq(parsed1.benchmark.version)
      expect(parsed2.test_result.rule_results.count).to eq(parsed1.test_result.rule_results.count)
    end
  end
end
