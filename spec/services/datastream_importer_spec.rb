# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatastreamImporter, type: :service do
  let(:fixture_path) { Rails.root.join('spec/fixtures/files/ssg-rhel7-ds.xml') }
  let(:op_profiles) { [instance_double('OpenscapProfile')] }
  let(:op_rule_groups) { [instance_double('OpenscapRuleGroup')] }
  let(:op_rules) { [instance_double('OpenscapRule')] }
  let(:op_value_definitions) { [instance_double('OpenscapValue')] }
  let(:rule_reference_with_label) { instance_double('OpenscapRuleReference', label: 'pci-dss') }
  let(:rule_reference_without_label) { instance_double('OpenscapRuleReference', label: '') }
  let(:op_security_guide) do
    instance_double(
      'OpenscapParser::Benchmark',
      profiles: op_profiles,
      groups: op_rule_groups,
      rules: op_rules,
      values: op_value_definitions,
      rule_references: [rule_reference_with_label, rule_reference_without_label]
    )
  end
  let(:datastream_file) { instance_double('OpenscapParser::DatastreamFile', benchmark: op_security_guide) }

  let(:importer) do
    allow_any_instance_of(described_class).to receive(:op_datastream_file).and_return(datastream_file)
    described_class.new(fixture_path)
  end

  describe '#initialize' do
    it 'loads the datastream from the fixture path' do
      expect_any_instance_of(described_class).to receive(:op_datastream_file)
        .with(fixture_path).and_return(datastream_file)

      described_class.new(fixture_path)
    end

    it 'caches the parsed components for later stages' do
      expect(importer.instance_variable_get(:@op_security_guide)).to eq(op_security_guide)
      expect(importer.instance_variable_get(:@op_profiles)).to eq(op_profiles)
      expect(importer.instance_variable_get(:@op_rule_groups)).to eq(op_rule_groups)
      expect(importer.instance_variable_get(:@op_rules)).to eq(op_rules)
      expect(importer.instance_variable_get(:@op_value_definitions)).to eq(op_value_definitions)
      expect(importer.instance_variable_get(:@op_rule_references)).to eq([rule_reference_with_label])
    end
  end

  describe '#import!' do
    it 'wraps the import in a V2::SecurityGuide transaction' do
      allow(::V2::SecurityGuide).to receive(:transaction).and_yield
      allow(importer).to receive(:save_all_security_guide_info)

      importer.import!

      expect(::V2::SecurityGuide).to have_received(:transaction)
      expect(importer).to have_received(:save_all_security_guide_info)
    end
  end
end
