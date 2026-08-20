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

  # Major 9 ships per-minor datastreams (hosted); major 8 ships only minor-0 (upstream/IoP).
  let(:supported) do
    [
      described_class.new(os_major_version: '9', os_minor_version: '0', version: '0.1.73'),
      described_class.new(os_major_version: '9', os_minor_version: '4', version: '0.1.81'),
      described_class.new(os_major_version: '8', os_minor_version: '0', version: '0.1.72')
    ]
  end

  before { allow(described_class).to receive(:all).and_return(supported) }

  describe '.minor_agnostic?' do
    it 'is false for a major shipping per-minor datastreams (hosted)' do
      expect(described_class.minor_agnostic?(9)).to be(false)
    end

    it 'is true for a major shipping only a minor-0 datastream (upstream/IoP)' do
      expect(described_class.minor_agnostic?(8)).to be(true)
    end

    it 'is false for an unknown major version' do
      expect(described_class.minor_agnostic?(10)).to be(false)
    end
  end

  describe '.resolve_minor' do
    context 'with per-minor (hosted) content' do
      it 'keeps the requested minor when the exact SSG entry exists' do
        expect(described_class.resolve_minor(9, 4)).to eq(4)
      end

      it 'keeps the requested minor even when no SSG entry ships for it' do
        expect(described_class.resolve_minor(9, 3)).to eq(3)
      end

      it 'coerces string arguments and returns an integer' do
        expect(described_class.resolve_minor('9', '4')).to eq(4)
      end

      it 'keeps the requested minor for an unknown major version' do
        expect(described_class.resolve_minor(10, 1)).to eq(1)
      end
    end

    context 'with minor-agnostic (upstream/IoP) content' do
      it 'collapses every minor onto minor 0' do
        expect(described_class.resolve_minor(8, 5)).to eq(0)
      end
    end
  end

  describe '.for_os' do
    context 'with per-minor (hosted) content' do
      it 'returns the exact entries when a matching minor exists' do
        expect(described_class.for_os(9, 4).map(&:os_minor_version)).to eq(['4'])
      end

      it 'returns nothing when no exact minor is shipped' do
        expect(described_class.for_os(9, 3)).to be_empty
      end

      it 'returns an empty array when the major version is unknown' do
        expect(described_class.for_os(10, 1)).to be_empty
      end
    end

    context 'with minor-agnostic (upstream/IoP) content' do
      it 'falls back to the minor-0 datastream for any minor' do
        expect(described_class.for_os(8, 5).map(&:os_minor_version)).to eq(['0'])
      end
    end
  end

  # Minors must compare as integers, not strings, or 8.10 behaves like 8.1.
  describe 'minor upgrades, downgrades and two-digit minors' do
    let(:supported) do
      [
        described_class.new(os_major_version: '8', os_minor_version: '0', version: '0.1.72'),
        described_class.new(os_major_version: '8', os_minor_version: '1', version: '0.1.73'),
        described_class.new(os_major_version: '8', os_minor_version: '10', version: '0.1.74'),
        described_class.new(os_major_version: '9', os_minor_version: '0', version: '0.1.72'),
        described_class.new(os_major_version: '9', os_minor_version: '1', version: '0.1.73'),
        described_class.new(os_major_version: '9', os_minor_version: '5', version: '0.1.74'),
        described_class.new(os_major_version: '7', os_minor_version: '0', version: '0.1.70')
      ]
    end

    it 'treats a two-digit minor as an integer, not a string prefix' do
      expect(described_class.resolve_minor(8, 10)).to eq(10)
      expect(described_class.resolve_minor(8, 1)).to eq(1)
      expect(described_class.for_os(8, 10).map(&:os_minor_version)).to eq(['10'])
    end

    it 'resolves each minor to itself across an upgrade 9.1 -> 9.5 (hosted)' do
      expect(described_class.resolve_minor(9, 1)).to eq(1)
      expect(described_class.resolve_minor(9, 5)).to eq(5)
    end

    it 'resolves each minor to itself across a downgrade 8.10 -> 8.1 (hosted)' do
      expect(described_class.resolve_minor(8, 10)).to eq(10)
      expect(described_class.resolve_minor(8, 1)).to eq(1)
    end

    it 'keeps an unshipped in-between minor as itself so the lookup 404s (hosted)' do
      expect(described_class.resolve_minor(9, 3)).to eq(3)
      expect(described_class.for_os(9, 3)).to be_empty
    end

    it 'collapses every minor (single and two-digit) onto 0 for minor-agnostic content' do
      expect(described_class.minor_agnostic?(7)).to be(true)
      expect(described_class.resolve_minor(7, 1)).to eq(0)
      expect(described_class.resolve_minor(7, 10)).to eq(0)
      expect(described_class.for_os(7, 10).map(&:os_minor_version)).to eq(['0'])
    end
  end
end
