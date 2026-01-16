# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe DatastreamImporter, type: :service do
  let(:datastream_filename) { Rails.root.join('spec/fixtures/files/ssg-rhel7-ds.xml') }

  let(:op_profiles) { [OpenStruct.new(id: 'profile1')] }
  let(:op_rule_groups) { [OpenStruct.new(id: 'group1')] }
  let(:op_rules) { [OpenStruct.new(id: 'rule1')] }
  let(:op_value_definitions) { [OpenStruct.new(id: 'value1')] }
  let(:op_rule_references) { [OpenStruct.new(label: 'label')] }

  let(:op_security_guide) do
    OpenStruct.new(
      profiles: op_profiles,
      groups: op_rule_groups,
      rules: op_rules,
      values: op_value_definitions,
      rule_references: op_rule_references
    )
  end

  let(:op_datastream) { OpenStruct.new(benchmark: op_security_guide) }

  let(:importer) { described_class.new(datastream_filename) }

  describe '#initialize' do
    before do
      allow_any_instance_of(DatastreamImporter).to receive(:op_datastream_file)
        .with(datastream_filename).and_return(op_datastream)
    end

    it 'loads the datastream from the fixture path' do
      expect(importer.instance_variable_get(:@op_security_guide)).to eq(op_security_guide)
      expect(importer.instance_variable_get(:@op_profiles)).to eq(op_profiles)
      expect(importer.instance_variable_get(:@op_rule_groups)).to eq(op_rule_groups)
      expect(importer.instance_variable_get(:@op_rules)).to eq(op_rules)
      expect(importer.instance_variable_get(:@op_value_definitions)).to eq(op_value_definitions)
      expect(importer.instance_variable_get(:@op_rule_references)).to eq(op_rule_references)
    end
  end

  describe '#import!' do
    before do
      allow(importer).to receive(:save_all_security_guide_info)
    end

    it 'runs save_all_security_guide_info inside a transaction' do
      expect(V2::SecurityGuide).to receive(:transaction).and_yield
      expect(importer).to receive(:save_all_security_guide_info)
      importer.import!
    end
  end
end
