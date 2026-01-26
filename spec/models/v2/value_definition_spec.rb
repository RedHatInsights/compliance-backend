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
end
