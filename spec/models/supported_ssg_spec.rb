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

      expect(ssg.version_with_revision).to be_a(Gem::Version)
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
end
