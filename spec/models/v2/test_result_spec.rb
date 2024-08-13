# frozen_string_literal: true

require 'rails_helper'

describe V2::TestResult do
  describe '.os_versions' do
    let(:versions) { ['7.1', '7.2', '7.3'] }

    let(:account) { FactoryBot.create(:account) }

    let(:policy) do
      FactoryBot.create(:v2_policy, os_major_version: 7, supports_minors: [1, 2, 3], account: account)
    end

    before do
      versions.each do |version|
        major, minor = version.split('.')
        FactoryBot.create_list(
          :system, (1..10).to_a.sample,
          os_major_version: major.to_i,
          os_minor_version: minor.to_i,
          policy_id: policy.id,
          account: account
        ).each do |sys|
          FactoryBot.create(:v2_test_result, system: sys, policy_id: policy.id)
        end
      end
    end

    subject { described_class.where.associated(:system) }

    it 'returns a unique and sorted set of all versions' do
      expect(subject.os_versions.to_set { |version| version.delete('"') }).to eq(versions.to_set)
    end
  end
end
