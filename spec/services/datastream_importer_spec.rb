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
      allow_any_instance_of(DatastreamImporter).to receive(:op_datastream_file)
        .with(datastream_filename).and_return(op_datastream)
      allow(importer).to receive(:save_all_security_guide_info)
    end

    it 'runs save_all_security_guide_info inside a transaction' do
      expect(SecurityGuide).to receive(:transaction).and_yield
      expect(importer).to receive(:save_all_security_guide_info)
      importer.import!
    end
  end

  context 'with a real RHEL-8 datastream', :slow do
    let(:importer) { described_class.new(file_fixture('ssg-rhel8-ds.xml').to_s) }

    before do
      allow(SupportedSsg).to receive(:by_os_major).and_return(
        '8' => [OpenStruct.new(version: '0.1.81', package: 'scap-security-guide-0.1.81-1.el8_10')]
      )
      allow(SupportedSsg).to receive(:by_ssg_version).and_return(
        '0.1.81' => [OpenStruct.new(os_major_version: '8', version: '0.1.81', os_minor_version: '10')]
      )
    end

    describe '#import!' do
      before { importer.import! }

      let(:security_guide) { SecurityGuide.find_by!(ref_id: 'xccdf_org.ssgproject.content_benchmark_RHEL-8') }

      it 'creates a security guide' do
        expect(security_guide).not_to be_nil
        expect(security_guide.version).to eq('0.1.81')
        expect(security_guide.os_major_version).to eq(8)
        expect(security_guide.package_name).to eq('scap-security-guide-0.1.81-1.el8_10')
      end

      it 'creates rule groups with ancestry' do
        rule_groups = RuleGroup.where(security_guide: security_guide)
        expect(rule_groups.count).to be > 0
        expect(rule_groups.pluck(:ref_id)).to all(start_with('xccdf_org.ssgproject.content_group_'))
        expect(rule_groups.where.not(ancestry: [nil, '']).count).to be > 0
      end

      it 'links rules to rule groups' do
        orphan_rules = Rule.where(security_guide: security_guide, rule_group_id: nil)
        expect(orphan_rules.count).to eq(0)
      end
    end
  end
end
