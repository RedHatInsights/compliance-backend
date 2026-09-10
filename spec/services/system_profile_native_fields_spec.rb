# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemProfileNativeFields do
  subject(:result) { described_class.normalize(profile) }

  describe '.normalize' do
    context 'with valid values' do
      let(:owner_id) { SecureRandom.uuid }
      let(:profile) do
        {
          'owner_id' => owner_id,
          'operating_system' => { 'major' => 9, 'minor' => 4 }
        }
      end

      it 'returns all native attributes without malformed flags' do
        expect(result.native_attributes).to eq(
          owner_id: owner_id,
          os_major_version: 9,
          os_minor_version: 4
        )
        expect(result).not_to be_malformed_owner_id
        expect(result).not_to be_malformed_os_major
        expect(result).not_to be_malformed_os_minor
      end
    end

    context 'with UUID forms accepted by the shared UUID helper' do
      let(:canonical) { SecureRandom.uuid }
      let(:profile) { { 'owner_id' => owner_id } }

      {
        canonical: ->(uuid) { uuid },
        uppercase: ->(uuid) { uuid.upcase },
        unhyphenated: ->(uuid) { uuid.delete('-') }
      }.each do |label, transform|
        context "with a #{label} owner_id" do
          let(:owner_id) { transform.call(canonical) }

          it 'preserves the accepted, persistence-compatible owner value' do
            type = System.type_for_attribute(:owner_id)
            expect(UUID.validate(owner_id)).to be(true)
            expect(type.serialize(owner_id)).not_to be_nil
            persisted_owner_id = type.cast(type.serialize(owner_id))
            expect(persisted_owner_id).not_to be_nil
            expect(result.owner_id).to eq(owner_id)
            expect(result).not_to be_malformed_owner_id

            system = FactoryBot.create(:system)
            # rubocop:disable Rails/SkipsModelValidations
            expect { system.update_columns(owner_id: result.owner_id) }.not_to raise_error
            # rubocop:enable Rails/SkipsModelValidations
            expect(system.reload[:owner_id]).to eq(persisted_owner_id)
          end
        end
      end
    end

    context 'with missing and null values' do
      let(:profiles) do
        [
          {},
          { 'owner_id' => nil },
          { 'operating_system' => nil },
          { 'operating_system' => { 'major' => nil, 'minor' => nil } }
        ]
      end

      it 'returns absence without malformed flags' do
        profiles.each do |profile|
          normalized = described_class.normalize(profile)
          expect(normalized.native_attributes.values).to all(be_nil)
          expect(normalized).not_to be_malformed_owner_id
          expect(normalized).not_to be_malformed_os_major
          expect(normalized).not_to be_malformed_os_minor
        end
      end
    end

    context 'with malformed owner values' do
      let(:profile) { {} }

      it 'classifies invalid strings and non-strings' do
        [Faker::Lorem.word, 1, {}, []].each do |owner_id|
          normalized = described_class.normalize('owner_id' => owner_id)
          expect(normalized.owner_id).to be_nil
          expect(normalized).to be_malformed_owner_id
        end
      end

      it 'classifies a helper-valid but persistence-incompatible UUID form' do
        owner_id = "urn:uuid:#{SecureRandom.uuid}"
        type = System.type_for_attribute(:owner_id)

        expect(UUID.validate(owner_id)).to be(true)
        expect(type.serialize(owner_id)).to be_nil
        expect(described_class.normalize('owner_id' => owner_id).owner_id).to be_nil
        expect(described_class.normalize('owner_id' => owner_id)).to be_malformed_owner_id
      end
    end

    context 'with Active Record-castable OS values' do
      let(:profile) { {} }

      it 'preserves merged importer casting behavior' do
        {
          '9' => 9,
          '09' => 9,
          '9x' => 9,
          '1.5' => 1,
          1.5 => 1,
          true => 1,
          false => 0
        }.each do |source, expected|
          normalized = described_class.normalize(
            'operating_system' => { 'major' => source }
          )
          expect(normalized.os_major_version).to eq(expected)
          expect(normalized).not_to be_malformed_os_major
        end
      end
    end

    context 'with non-null OS values that cast to nil' do
      let(:profile) { {} }

      it 'classifies each affected field independently' do
        [[], {}].each do |source|
          normalized = described_class.normalize(
            'operating_system' => { 'major' => source, 'minor' => 4 }
          )
          expect(normalized.os_major_version).to be_nil
          expect(normalized).to be_malformed_os_major
          expect(normalized.os_minor_version).to eq(4)
          expect(normalized).not_to be_malformed_os_minor
        end
      end
    end

    context 'with a non-null non-Hash operating_system' do
      let(:profile) { { 'operating_system' => Faker::Lorem.word } }

      it 'classifies both OS fields as malformed' do
        expect(result.os_major_version).to be_nil
        expect(result.os_minor_version).to be_nil
        expect(result).to be_malformed_os_major
        expect(result).to be_malformed_os_minor
      end
    end

    context 'with an out-of-range OS integer' do
      let(:overflow) { 2_147_483_648 }
      let(:profile) { { 'operating_system' => { 'major' => overflow } } }

      it 'preserves the cast value for database serialization to reject' do
        expect(result.os_major_version).to eq(overflow)
        expect(result).not_to be_malformed_os_major
        expect do
          System.type_for_attribute(:os_major_version).serialize(result.os_major_version)
        end.to raise_error(ActiveModel::RangeError)
      end
    end
  end
end
