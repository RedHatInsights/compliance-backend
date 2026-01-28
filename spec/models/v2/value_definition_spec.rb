# frozen_string_literal: true

require 'rails_helper'

describe V2::ValueDefinition do
  describe '#validate_value' do
    subject { FactoryBot.create(:v2_value_definition, value_type: value_type) }

    let(:value_type) { 'string' }

    it 'rejects non-string values' do
      expect(subject.validate_value(true)).to be false
      expect(subject.validate_value(false)).to be false
      expect(subject.validate_value(42)).to be false
      expect(subject.validate_value(nil)).to be false
      expect(subject.validate_value([])).to be false
    end

    context 'with boolean value_type' do
      let(:value_type) { 'boolean' }

      it 'accepts "true"' do
        expect(subject.validate_value('true')).to be true
      end

      it 'accepts "false"' do
        expect(subject.validate_value('false')).to be true
      end

      it 'rejects other strings' do
        expect(subject.validate_value('yes')).to be false
        expect(subject.validate_value('1')).to be false
        expect(subject.validate_value('TRUE')).to be false
      end
    end

    context 'with number value_type' do
      let(:value_type) { 'number' }

      it 'accepts integer strings' do
        expect(subject.validate_value('42')).to be true
        expect(subject.validate_value('0')).to be true
        expect(subject.validate_value('-1')).to be true
      end

      it 'rejects non-numeric strings' do
        expect(subject.validate_value('abc')).to be false
        expect(subject.validate_value('12.34')).to be false
        expect(subject.validate_value('1a2')).to be false
      end
    end

    context 'with string value_type' do
      let(:value_type) { 'string' }

      it 'accepts any string value' do
        expect(subject.validate_value('hello')).to be true
        expect(subject.validate_value('')).to be true
        expect(subject.validate_value('123')).to be true
        expect(subject.validate_value('special!@#$%')).to be true
      end
    end
  end

  describe '.from_parser' do
    let(:security_guide) { FactoryBot.create(:v2_security_guide) }

    let(:value_type) { 'string' }
    let(:parser_obj) do
      OpenStruct.new(
        id: "xccdf_org.ssgproject.content_value_#{SecureRandom.hex}",
        title: Faker::Lorem.sentence,
        description: Faker::Lorem.paragraph,
        type: value_type,
        value: Faker::Lorem.word
      )
    end

    context 'creating a new record' do
      subject do
        described_class.from_parser(
          parser_obj,
          security_guide_id: security_guide.id
        )
      end

      it 'sets attributes from parser object' do
        expect(subject.attributes.slice(
                 'ref_id', 'security_guide_id', 'title', 'description', 'value_type', 'default_value'
               )).to eq(
                 'ref_id' => parser_obj.id,
                 'security_guide_id' => security_guide.id,
                 'title' => parser_obj.title,
                 'description' => parser_obj.description,
                 'value_type' => parser_obj.type,
                 'default_value' => parser_obj.value
               )

        expect(subject).not_to be_persisted
      end
    end

    context 'updating an existing record' do
      let(:existing) { FactoryBot.create(:v2_value_definition, security_guide: security_guide) }

      subject do
        described_class.from_parser(
          parser_obj,
          existing: existing,
          security_guide_id: security_guide.id
        )
      end

      it 'only updates the fields necessary' do
        expect(subject.id).to eq(existing.id)
        expect(subject.has_changes_to_save?).to be_truthy

        expect(subject.attributes.slice('title', 'description', 'value_type', 'default_value')).to eq(
          'title' => parser_obj.title,
          'description' => parser_obj.description,
          'value_type' => parser_obj.type,
          'default_value' => parser_obj.value
        )
      end
    end
  end
end
