# frozen_string_literal: true

require 'rails_helper'

describe System do
  describe 'database indexes' do
    let(:indexes) { ActiveRecord::Base.connection.indexes('systems') }

    it 'defines expected partial and expression indexes on systems table' do
      index_names = indexes.map(&:name)

      expect(index_names).to include(
        'index_systems_on_deleted_at_partial',
        'index_systems_on_org_id_and_id_partial',
        'index_systems_on_org_id_and_display_name_partial',
        'index_systems_on_owner_id_partial',
        'index_systems_on_org_id_and_os_version_partial',
        'index_systems_on_tags_gin_partial',
        'index_systems_on_groups_gin_partial',
        'index_systems_on_empty_groups_partial'
      )
    end

    it 'configures correct partial conditions for active system indexes' do
      active_indexes = indexes.select { |i| i.name.end_with?('_partial') }

      active_indexes.each do |index|
        expect(index.where).to be_present
      end
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
