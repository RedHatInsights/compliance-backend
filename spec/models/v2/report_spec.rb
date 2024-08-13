# frozen_string_literal: true

require 'rails_helper'

describe V2::Report do
  describe '.os_versions' do
    let(:versions) { [7, 8, 9] }

    before do
      versions.each do |version|
        FactoryBot.create_list(:v2_policy, (1..10).to_a.sample, os_major_version: version)
      end
    end

    subject { described_class.where.associated(:security_guide) }

    it 'returns a unique and sorted set of all versions' do
      expect(subject.os_versions).to eq(versions)
    end
  end
end
