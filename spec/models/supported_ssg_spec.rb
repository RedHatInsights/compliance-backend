# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SupportedSsg do
  describe '#version_with_revision' do
    it 'parses downstream package with .el suffix' do
      ssg = described_class.new(
        id: 'RHEL-8.0:scap-security-guide-0.1.79-1.el8',
        package: 'scap-security-guide-0.1.79-1.el8',
        version: '0.1.79',
        os_major_version: '8',
        os_minor_version: '0'
      )

      expect(ssg.version_with_revision).to eq(Gem::Version.new('0.1.79-1'))
    end

    it 'parses upstream package without .el suffix' do
      ssg = described_class.new(
        id: 'RHEL-9.0:scap-security-guide-0.1.81',
        package: 'scap-security-guide-0.1.81',
        version: '0.1.81',
        os_major_version: '9',
        os_minor_version: '0'
      )

      expect(ssg.version_with_revision).to eq(Gem::Version.new('0.1.81'))
    end

    it 'strips the .el suffix completely' do
      ssg = described_class.new(
        id: 'RHEL-9.4:scap-security-guide-0.1.73-2.el9_4',
        package: 'scap-security-guide-0.1.73-2.el9_4',
        version: '0.1.73',
        os_major_version: '9',
        os_minor_version: '4'
      )

      expect(ssg.version_with_revision).to eq(Gem::Version.new('0.1.73-2'))
    end
  end

  describe '.resolve_minor' do
    let(:supported) do
      [
        described_class.new(os_major_version: '9', os_minor_version: '0', version: '0.1.73'),
        described_class.new(os_major_version: '9', os_minor_version: '4', version: '0.1.81'),
        described_class.new(os_major_version: '8', os_minor_version: '0', version: '0.1.72')
      ]
    end

    before { allow(described_class).to receive(:all).and_return(supported) }

    it 'returns the exact minor when a matching SSG entry exists' do
      expect(described_class.resolve_minor(9, 4)).to eq(4)
    end

    it 'falls back to minor 0 when no matching SSG entry exists' do
      expect(described_class.resolve_minor(9, 3)).to eq(0)
    end

    it 'coerces string arguments and returns an integer' do
      expect(described_class.resolve_minor('9', '4')).to eq(4)
    end

    it 'falls back to 0 for an entirely unknown major version' do
      expect(described_class.resolve_minor(10, 1)).to eq(0)
    end
  end

  describe '.for_os' do
    let(:supported) do
      [
        described_class.new(os_major_version: '9', os_minor_version: '0', version: '0.1.73'),
        described_class.new(os_major_version: '9', os_minor_version: '4', version: '0.1.81'),
        described_class.new(os_major_version: '8', os_minor_version: '0', version: '0.1.72')
      ]
    end

    before { allow(described_class).to receive(:all).and_return(supported) }

    it 'returns the exact entries when a matching minor exists' do
      expect(described_class.for_os(9, 4).map(&:os_minor_version)).to eq(['4'])
    end

    it 'falls back to the minor 0 entry when no exact minor exists' do
      expect(described_class.for_os(9, 3).map(&:os_minor_version)).to eq(['0'])
    end

    it 'returns an empty array when the major version is unknown' do
      expect(described_class.for_os(10, 1)).to be_empty
    end
  end
end
