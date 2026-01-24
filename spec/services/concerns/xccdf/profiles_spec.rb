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

      # NOTE: taken from `app/services/concerns/xccdf/value_definitions.rb`
      def value_definition_for(ref_id:)
        @value_definitions.index_by(&:ref_id)[ref_id]
      end
    end.new(
      security_guide: security_guide,
      op_profiles: op_profiles,
      value_definitions: value_definitions
    )
  end

  let(:security_guide) { FactoryBot.create(:v2_security_guide) }

  # NOTE: This method originates from the openscap-parser gem. (see GitHub)
  # OpenSCAP/openscap_parser/blob/62de6ab7cd670b1ad54702b34dc4e459958112eb/lib/openscap_parser/value.rb#L45C4-L47C8
  let(:value_parser_class) do
    Struct.new(:id, :title, :description, :type, :default_value, :overrides, keyword_init: true) do
      def value(selector = nil)
        selector ? overrides[selector] : default_value
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

  let(:op_selector_to_update) { 'stricter' }
  let(:op_profile_to_update) do
    OpenStruct.new(
      id: stale_profile_record.ref_id,
      title: stale_profile_record.title,
      description: stale_profile_record.description,
      refined_values: { op_value_definition.id => op_selector_to_update }
    )
  end

  let(:op_new_selector) { 'permissive' }
  let(:op_new_profile) do
    OpenStruct.new(
      id: Faker::Lorem.word,
      title: Faker::Lorem.word,
      description: Faker::Lorem.sentence,
      refined_values: { op_value_definition.id => op_new_selector }
    )
  end

  let(:op_profiles) { [op_profile_to_update, op_new_profile] }

  describe '#save_profiles' do
    it 'upserts parsed profiles' do
      expect do
        service.save_profiles
      end.to change {
        V2::Profile.where(security_guide: security_guide).count
      }.from(1).to(op_profiles.count)

      created = V2::Profile.find_by(ref_id: op_new_profile.id, security_guide: security_guide)
      expect(created).not_to be_nil
      expect(created.attributes.slice('title', 'description', 'value_overrides')).to eq(
        'title' => op_new_profile.title,
        'description' => op_new_profile.description,
        'value_overrides' => { value_definition.id.to_s => op_value_definition.value(op_new_value) }
      )

      refreshed = stale_profile_record.reload
      expect(refreshed.attributes.slice('title', 'description', 'value_overrides')).to eq(
        'title' => op_profile_to_update.title,
        'description' => op_profile_to_update.description,
        'value_overrides' => { value_definition.id.to_s => op_value_definition.value(op_selector_to_update) }
      )
    end
  end

  describe '#profiles' do
    it 'returns all the parsed profiles that were changed or added' do
      results = service.profiles

      refreshed = results.find { |profile| profile.ref_id == stale_profile_record.ref_id }
      created = results.find { |profile| profile.ref_id == op_new_profile.id }

      expect(refreshed.id).to eq(stale_profile_record.id)
      expect(refreshed).to be_persisted

      expect(created).not_to be_persisted
      expect(created.security_guide_id).to eq(security_guide.id)
    end
  end
end
