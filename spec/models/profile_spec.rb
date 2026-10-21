# frozen_string_literal: true

require 'rails_helper'

describe Profile do
  describe '#variant_for_minor' do
    let(:subject) { FactoryBot.create(:profile) }

    context 'single variant' do
      let!(:result) do
        FactoryBot.create(
          :profile,
          ref_id: subject.ref_id,
          supports_minors: [0],
          security_guide: FactoryBot.create(:security_guide, version: '0.1.0')
        )
      end

      it 'returns with the only one' do
        expect(subject.variant_for_minor(0)).to eq(result)
      end
    end

    context 'multiple variants' do
      let!(:result) do
        FactoryBot.create(
          :profile,
          ref_id: subject.ref_id,
          supports_minors: [0],
          security_guide: FactoryBot.create(:security_guide, version: '0.1.0')
        )
      end

      before do
        3.times do |i|
          FactoryBot.create(
            :profile,
            ref_id: subject.ref_id,
            supports_minors: [0],
            security_guide: FactoryBot.create(:security_guide, version: "0.0.#{i}")
          )
        end
      end

      it 'returns with the latest' do
        expect(subject.variant_for_minor(0)).to eq(result)
      end
    end

    context 'no variant' do
      it 'raises an error' do
        expect { subject.variant_for_minor(0) }.to raise_exception(Exceptions::OSMinorVersionNotSupported)
      end
    end

    context 'when SupportedSsg has no entry for the requested minor' do
      before { allow(SupportedSsg).to receive(:resolve_minor).and_return(0) }

      let!(:result) do
        FactoryBot.create(
          :profile,
          ref_id: subject.ref_id,
          supports_minors: [0],
          security_guide: FactoryBot.create(:security_guide, version: '999.0.0')
        )
      end

      it 'falls back to minor 0 via resolve_minor' do
        expect(subject.variant_for_minor(4)).to eq(result)
      end
    end
  end
end
