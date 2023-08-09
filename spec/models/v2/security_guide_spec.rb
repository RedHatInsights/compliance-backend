# frozen_string_literal: true

require 'rails_helper'

describe V2::SecurityGuide do
  subject { FactoryBot.create(:v2_security_guide, os_major_version: os_version) }

  describe 'os_major_version' do
    context 'single digit os_major_version' do
      let(:os_version) { 7 }

      it 'returns correct os_major_version' do
        expect(subject.os_major_version).to eq(os_version)
      end
    end

    context 'double digit os_major_version' do
      let(:os_version) { 15 }

      it 'returns correct os_major_version' do
        expect(subject.os_major_version).to eq(15)
      end
    end
  end
end
