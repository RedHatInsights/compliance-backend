# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionManagerId do
  describe '.canonical' do
    let(:canonical_id) { Faker::Internet.uuid }

    it 'returns a stripped uuid' do
      expect(described_class.canonical("  #{canonical_id}  ")).to eq(canonical_id)
    end

    it 'accepts uppercase and unhyphenated forms without rewriting them' do
      uppercase = canonical_id.upcase
      compact = canonical_id.delete('-')

      expect(described_class.canonical(uppercase)).to eq(uppercase)
      expect(described_class.canonical(compact)).to eq(compact)
    end

    it 'returns nil for blank values' do
      expect(described_class.canonical(nil)).to be_nil
      expect(described_class.canonical('   ')).to be_nil
    end

    it 'returns nil for values that are not persistence-compatible uuids' do
      expect(described_class.canonical(Faker::Lorem.word)).to be_nil
      expect(described_class.canonical("urn:uuid:#{canonical_id}")).to be_nil
    end
  end

  describe '.for_import' do
    let(:canonical_id) { Faker::Internet.uuid }

    it 'returns nil for a blank value' do
      expect(described_class.for_import('   ')).to be_nil
    end

    it 'returns a persistence-compatible value' do
      expect(described_class.for_import(canonical_id)).to eq(canonical_id)
    end

    it 'raises when the value is not persistence-compatible' do
      expect { described_class.for_import(Faker::Lorem.word) }.to raise_error(described_class::Malformed)
      expect { described_class.for_import("urn:uuid:#{canonical_id}") }.to raise_error(described_class::Malformed)
    end
  end

  describe '.absent?' do
    it 'treats nil and whitespace as absent' do
      expect(described_class.absent?(nil)).to be(true)
      expect(described_class.absent?('   ')).to be(true)
      expect(described_class.absent?(Faker::Internet.uuid)).to be(false)
    end
  end
end
