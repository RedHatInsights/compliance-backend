# frozen_string_literal: true

require 'rails_helper'

describe V2::Profile do
  describe '#variant_for_minor' do
    let(:subject) { FactoryBot.create(:v2_profile) }

    context 'single variant' do
      let!(:result) do
        FactoryBot.create(
          :v2_profile,
          ref_id: subject.ref_id,
          supports_minors: [0],
          security_guide: FactoryBot.create(:v2_security_guide, version: '0.1.0')
        )
      end

      it 'returns with the only one' do
        expect(subject.variant_for_minor(0)).to eq(result)
      end
    end

    context 'multiple variants' do
      let!(:result) do
        FactoryBot.create(
          :v2_profile,
          ref_id: subject.ref_id,
          supports_minors: [0],
          security_guide: FactoryBot.create(:v2_security_guide, version: '0.1.0')
        )
      end

      before do
        3.times do |i|
          FactoryBot.create(
            :v2_profile,
            ref_id: subject.ref_id,
            supports_minors: [0],
            security_guide: FactoryBot.create(:v2_security_guide, version: "0.0.#{i}")
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
  end
end
