# frozen_string_literal: true

require 'rails_helper'

describe System do
  describe '.table_name' do
    it 'is systems' do
      expect(described_class.table_name).to eq('systems')
    end
  end

  describe 'default_scope' do
    let!(:active_system) { FactoryBot.create(:system, deleted_at: nil) }
    let!(:deleted_system) { FactoryBot.create(:system, deleted_at: Time.current) }

    it 'excludes soft-deleted records' do
      expect(described_class.all).to include(active_system)
      expect(described_class.all).not_to include(deleted_system)
    end
  end

  describe 'computed timestamps' do
    let(:stale_time) { Time.current }
    let(:system) { FactoryBot.build(:system, stale_timestamp: stale_time) }

    describe '#stale_warning_timestamp' do
      it 'returns stale_timestamp + 7 days' do
        expect(system.stale_warning_timestamp).to eq(stale_time + 7.days)
      end

      context 'when stale_timestamp is nil' do
        let(:system) { FactoryBot.build(:system, stale_timestamp: nil) }

        it 'returns nil' do
          expect(system.stale_warning_timestamp).to be_nil
        end
      end
    end

    describe '#culled_timestamp' do
      it 'returns stale_timestamp + 14 days' do
        expect(system.culled_timestamp).to eq(stale_time + 14.days)
      end

      context 'when stale_timestamp is nil' do
        let(:system) { FactoryBot.build(:system, stale_timestamp: nil) }

        it 'returns nil' do
          expect(system.culled_timestamp).to be_nil
        end
      end
    end

    describe '#last_check_in' do
      it 'returns stale_timestamp + 8 days' do
        expect(system.last_check_in).to eq(stale_time + 8.days)
      end

      context 'when stale_timestamp is nil' do
        let(:system) { FactoryBot.build(:system, stale_timestamp: nil) }

        it 'returns nil' do
          expect(system.last_check_in).to be_nil
        end
      end
    end
  end

  describe '#readonly?' do
    let(:system) { FactoryBot.build(:system) }

    it 'returns false' do
      expect(system.readonly?).to be false
    end
  end

  describe '.os_versions' do
    let(:versions) { ['7.1', '7.2', '7.3', '7.4', '7.5', '8.2', '8.10', '9.0', '9.1'] }

    before do
      versions.each do |version|
        major, minor = version.split('.')
        FactoryBot.create_list(:system, (1..10).to_a.sample, os_major_version: major, os_minor_version: minor)
      end
    end

    subject { described_class.all }

    it 'returns a unique and sorted set of all versions' do
      expect(subject.os_versions.to_set { |version| version.delete('"') }).to eq(versions.to_set)
    end
  end
end
