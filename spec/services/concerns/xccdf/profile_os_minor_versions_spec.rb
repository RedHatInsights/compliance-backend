# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Xccdf::ProfileOsMinorVersions do
  subject(:service) do
    Class.new do
      include Xccdf::ProfileOsMinorVersions

      def initialize(profiles:, security_guide:)
        @profiles = profiles
        @security_guide = security_guide
      end
    end.new(profiles: profiles, security_guide: security_guide)
  end

  let(:security_guide) { FactoryBot.create(:v2_security_guide, version: '0.1.57', os_major_version: 7) }
  let(:profiles) { FactoryBot.create_list(:v2_profile, 2, security_guide: security_guide) }
  let(:supported_entries) do
    [
      SupportedSsg.new(
        id: 'rhel7:pkg1',
        package: 'pkg1',
        version: security_guide.version,
        profiles: [],
        os_major_version: security_guide.os_major_version,
        os_minor_version: 3
      ),
      SupportedSsg.new(
        id: 'rhel7:pkg2',
        package: 'pkg2',
        version: security_guide.version,
        profiles: [],
        os_major_version: security_guide.os_major_version,
        os_minor_version: 4
      )
    ]
  end

  before do
    allow(SupportedSsg).to receive(:by_ssg_version)
      .with(true)
      .and_return({ security_guide.version => supported_entries })
  end

  describe '#save_profile_os_minor_versions' do
    let!(:stale_mapping) { FactoryBot.create(:profile_os_minor_version, profile: profiles.first, os_minor_version: 1) }
    let!(:unrelated_mapping) { FactoryBot.create(:profile_os_minor_version) }

    it 'replaces the mappings for the configured profiles using supported minor versions' do
      expect do
        service.save_profile_os_minor_versions
      end.to change {
        V2::ProfileOsMinorVersion.where(profile_id: profiles.map(&:id)).count
      }.from(1).to(profiles.count * supported_entries.count)

      expect { stale_mapping.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { unrelated_mapping.reload }.not_to raise_error

      resulting_matrix = V2::ProfileOsMinorVersion.where(profile: profiles).pluck(:profile_id, :os_minor_version)
      expected_matrix = profiles.flat_map do |profile|
        supported_entries.map { |entry| [profile.id, entry.os_minor_version] }
      end

      expect(resulting_matrix).to match_array(expected_matrix)
    end
  end
end
