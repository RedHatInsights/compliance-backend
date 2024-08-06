# frozen_string_literal: true

require 'rails_helper'

describe V2::System do
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
