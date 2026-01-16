# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::SecurityGuides do
  subject(:service) do
    Class.new do
      include Xccdf::SecurityGuides

      attr_reader :os_major_version

      def initialize(op_security_guide:, os_major_version:)
        @op_security_guide = op_security_guide
        @os_major_version = os_major_version
      end
    end.new(op_security_guide: op_security_guide, os_major_version: '7')
  end

  let(:op_security_guide) do
    OpenStruct.new(
      id: 'xccdf_org.ssgproject.content_benchmark_RHEL-7',
      version: '0.1.57',
      title: 'RHEL 7 Benchmark',
      description: 'Latest benchmark',
      profiles: Array.new(2) { double('Profile') },
      rules: Array.new(3) { double('Rule') }
    )
  end

  let(:supported_entry) { OpenStruct.new(version: op_security_guide.version, package: 'ssg-rhel7') }

  before do
    allow(SupportedSsg).to receive(:by_os_major).and_return({ '7' => [supported_entry] })
    Settings.force_import_ssgs ||= false
  end

  describe '#save_security_guide' do
    it 'persists the parsed security guide with the resolved package name' do
      expect do
        service.save_security_guide
      end.to change(V2::SecurityGuide, :count).by(1)

      record = V2::SecurityGuide.find_by(ref_id: op_security_guide.id, version: op_security_guide.version)
      expect(record.package_name).to eq('ssg-rhel7')
    end

    it 'does not touch an already up-to-date record' do
      existing = FactoryBot.create(:v2_security_guide,
                                   ref_id: op_security_guide.id,
                                   version: op_security_guide.version,
                                   os_major_version: '7',
                                   package_name: 'ssg-rhel7')
      previous_timestamp = existing.updated_at

      service.save_security_guide

      expect(existing.reload.updated_at).to eq(previous_timestamp)
    end
  end

  describe '#security_guide_contents_equal_to_op?' do
    let(:guide_record) do
      FactoryBot.create(:v2_security_guide,
                        ref_id: op_security_guide.id,
                        version: op_security_guide.version,
                        os_major_version: '7',
                        package_name: 'ssg-rhel7')
    end

    before do
      allow(service).to receive(:security_guide).and_return(guide_record)
      allow(Settings).to receive(:force_import_ssgs).and_return(false)
    end

    context 'when profile and rule counts match the parser data' do
      before do
        FactoryBot.create_list(:v2_profile, op_security_guide.profiles.count, security_guide: guide_record)
        FactoryBot.create_list(:v2_rule, op_security_guide.rules.count, security_guide: guide_record)
      end

      it 'returns true' do
        expect(service.security_guide_contents_equal_to_op?).to be(true)
      end
    end

    context 'when the stored data diverges from the parser feed' do
      before do
        FactoryBot.create_list(:v2_profile, 1, security_guide: guide_record)
        FactoryBot.create_list(:v2_rule, op_security_guide.rules.count, security_guide: guide_record)
      end

      it 'requires a refresh' do
        expect(service.security_guide_contents_equal_to_op?).to be(false)
      end
    end

    context 'when forced imports are enabled' do
      before { allow(Settings).to receive(:force_import_ssgs).and_return(true) }

      it 'skips the equality checks' do
        expect(service.security_guide_contents_equal_to_op?).to be(false)
      end
    end
  end
end
