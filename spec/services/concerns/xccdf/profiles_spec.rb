# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::Profiles do
  ProfileParser = Struct.new(:id, :title, :description, :refined_values, keyword_init: true)

  ValueParser = Struct.new(:id, :title, :description, :type, :default_value, :overrides, keyword_init: true) do
    def value(selector = nil)
      selector ? overrides.fetch(selector, selector) : default_value
    end
  end

  subject(:service) do
    value_lookup = value_definitions.index_by(&:ref_id)

    Class.new do
      include Xccdf::Profiles

      def initialize(security_guide:, op_profiles:, value_lookup:)
        @security_guide = security_guide
        @op_profiles = op_profiles
        @value_lookup = value_lookup
      end

      private

      def value_definition_for(ref_id:)
        @value_lookup.fetch(ref_id)
      end
    end.new(
      security_guide: security_guide,
      op_profiles: op_profiles,
      value_lookup: value_lookup
    )
  end

  let(:security_guide) { create(:v2_security_guide) }

  let(:value_parser) do
    ValueParser.new(
      id: 'xccdf_value_password_complexity',
      title: 'Password complexity',
      description: 'Complexity requirement',
      type: 'string',
      default_value: 'default',
      overrides: { 'strict' => 'strict-mode', 'permissive' => 'low' }
    )
  end

  let!(:value_definition) do
    create(:v2_value_definition, security_guide: security_guide, ref_id: value_parser.id).tap do |record|
      record.op_source = value_parser
    end
  end

  let(:value_definitions) { [value_definition] }

  let!(:existing_profile) do
    create(:v2_profile,
           security_guide: security_guide,
           ref_id: 'xccdf_profile_baseline',
           title: 'Legacy Baseline',
           description: 'Outdated profile',
           value_overrides: {})
  end

  let!(:unrelated_profile) { create(:v2_profile) }

  let(:baseline_profile_parser) do
    ProfileParser.new(
      id: existing_profile.ref_id,
      title: 'Updated Baseline',
      description: 'Refreshed profile description',
      refined_values: { value_parser.id => 'strict' }
    )
  end

  let(:hardening_profile_parser) do
    ProfileParser.new(
      id: 'xccdf_profile_hardening',
      title: 'Hardening profile',
      description: 'New profile from parser',
      refined_values: { value_parser.id => 'permissive' }
    )
  end

  let(:op_profiles) { [baseline_profile_parser, hardening_profile_parser] }

  describe '#save_profiles' do
    before { service.save_profiles }

    it 'creates missing profiles from the parser feed' do
      created = V2::Profile.find_by(ref_id: hardening_profile_parser.id, security_guide: security_guide)

      expect(created).not_to be_nil
      expect(created.title).to eq('Hardening profile')
      expect(created.value_overrides.values).to contain_exactly('low')
    end

    it 'updates profiles that already exist for the guide' do
      expect(existing_profile.reload.title).to eq('Updated Baseline')
      expect(existing_profile.description).to eq('Refreshed profile description')
      expect(existing_profile.value_overrides[value_definition.id]).to eq('strict-mode')
    end

    it 'leaves profiles for other guides untouched' do
      expect { unrelated_profile.reload }.not_to raise_error
      expect(unrelated_profile.attributes).to match(a_hash_including('title' => unrelated_profile.title))
    end
  end
end
