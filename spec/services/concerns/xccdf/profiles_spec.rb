# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::Profiles do
  subject(:service) do
    Class.new do
      include Xccdf::Profiles

      def initialize(security_guide:, op_profiles:, value_definitions:)
        @security_guide = security_guide
        @op_profiles = op_profiles
        @value_definitions = value_definitions
      end

      private

      def value_definition_for(ref_id:)
        @value_definitions.index_by(&:ref_id)[ref_id]
      end
    end.new(
      security_guide: security_guide,
      op_profiles: op_profiles,
      value_definitions: value_definitions
    )
  end

  let(:security_guide) { create(:v2_security_guide) }

  let(:value_parser_class) do
    Struct.new(:id, :title, :description, :type, :default_value, :overrides, keyword_init: true) do
      def value(selector = nil)
        selector ? overrides.fetch(selector, selector) : default_value
      end
    end
  end

  let(:op_value_definition) do
    value_parser_class.new(
      id: 'xccdf_value_password_complexity',
      title: 'Password complexity',
      description: 'Control password strength',
      type: 'string',
      default_value: 'default',
      overrides: { 'strict' => 'strict-mode', 'permissive' => 'low' }
    )
  end

  let!(:value_definition) do
    FactoryBot.create(
      :v2_value_definition,
      security_guide: security_guide,
      ref_id: op_value_definition.id
    ).tap do |record|
      record.op_source = op_value_definition
    end
  end

  let(:value_definitions) { [value_definition] }

  let!(:stale_profile_record) do
    FactoryBot.create(
      :v2_profile,
      security_guide: security_guide,
      value_count: 2,
      supports_minors: [0]
    )
  end

  let!(:unrelated_profile_record) { FactoryBot.create(:v2_profile) }

  let(:op_updated_profile) do
    OpenStruct.new(
      id: stale_profile_record.ref_id,
      title: stale_profile_record.title,
      description: stale_profile_record.description,
      refined_values: { op_value_definition.id => 'strict' }
    )
  end

  let(:op_new_profile) do
    OpenStruct.new(
      id: Faker::Lorem.word,
      title: Faker::Lorem.word,
      description: Faker::Lorem.sentence,
      refined_values: { op_value_definition.id => 'permissive' }
    )
  end

  let(:op_profiles) { [op_updated_profile, op_new_profile] }

  describe '#save_profiles' do
    let!(:tailoring) do
      policy = FactoryBot.create(
        :v2_policy,
        profile: stale_profile_record,
        supports_minors: [0],
        os_major_version: security_guide.os_major_version
      )

      FactoryBot.create(:v2_tailoring, policy: policy, os_minor_version: 0).tap do |record|
        record.update_column(:value_overrides, {})
      end
    end

    it 'upserts parsed profiles' do
      expect do
        service.save_profiles
      end.to change {
        V2::Profile.where(security_guide: security_guide).count
      }.by(1)

      created = V2::Profile.find_by(ref_id: op_new_profile.id, security_guide: security_guide)
      expect(created).not_to be_nil
      expect(created.title).to eq(op_new_profile.title)
      expect(created.description).to eq(op_new_profile.description)
      expect(created.value_overrides[value_definition.id.to_s]).to eq('low')

      refreshed = stale_profile_record.reload
      expect(refreshed.title).to eq(op_updated_profile.title)
      expect(refreshed.description).to eq(op_updated_profile.description)
      expect(refreshed.value_overrides[value_definition.id.to_s]).to eq('strict-mode')

      expect(tailoring.reload.value_overrides[value_definition.id.to_s]).to eq('strict-mode')

      expect { unrelated_profile_record.reload }.not_to raise_error
    end
  end

  describe '#profiles' do
    it 'returns all the parsed profiles that were changed' do
      results = service.profiles

      refreshed = results.find { |profile| profile.ref_id == stale_profile_record.ref_id }
      created = results.find { |profile| profile.ref_id == op_new_profile.id }

      expect(refreshed.id).to eq(stale_profile_record.id)
      expect(refreshed).to be_persisted
      expect(refreshed.title).to eq(op_updated_profile.title)
      expect(refreshed.description).to eq(op_updated_profile.description)
      expect(refreshed.value_overrides[value_definition.id]).to eq('strict-mode')

      expect(created).not_to be_persisted
      expect(created.security_guide_id).to eq(security_guide.id)
      expect(created.title).to eq(op_new_profile.title)
      expect(created.description).to eq(op_new_profile.description)
      expect(created.value_overrides[value_definition.id]).to eq('low')
    end
  end
end
