# frozen_string_literal: true

require 'rails_helper'

describe Policy do
  let(:account) { FactoryBot.create(:account) }

  describe '#os_major_version' do
    let(:policy) { FactoryBot.create(:policy, os_major_version: os_major_version, account: account) }

    subject { policy }

    [7, 8, 9].each do |os|
      context "os_major_version is #{os}" do
        let(:os_major_version) { os }

        it 'returns with the correct version' do
          expect(subject.os_major_version).to eq(os)
        end
      end
    end

    context 'with autojoin' do
      subject do
        Policy.where.associated(:security_guide).select(
          described_class.arel_table[Arel.star],
          'security_guide.os_major_version AS security_guide__os_major_version'
        ).find(policy.id)
      end

      # Mock the security_guide method to fail the test if autojoin doesn't work
      before { allow(subject).to receive(:security_guide).and_return(nil) }

      [7, 8, 9].each do |os|
        context "os_major_version is #{os}" do
          let(:os_major_version) { os }

          it 'returns with the correct version' do
            expect(subject.os_major_version).to eq(os)
          end
        end
      end
    end
  end

  describe '#profile_title' do
    let(:profile) { FactoryBot.create(:profile) }
    let(:policy) { FactoryBot.create(:policy, account: account, profile: profile) }

    subject { policy }

    it 'returns with the correct title' do
      expect(subject.profile_title).to eq(profile.title)
    end

    context 'with autojoin' do
      subject do
        Policy.where.associated(:profile).select(
          described_class.arel_table[Arel.star],
          'profile.title AS profile__title'
        ).find(policy.id)
      end

      # Mock the profile method to fail the test if autojoin doesn't work
      before { allow(subject).to receive(:profile).and_return(nil) }

      it 'returns with the correct title' do
        expect(subject.profile_title).to eq(profile.title)
      end
    end
  end

  describe '#supports_minor?' do
    let(:policy) { FactoryBot.build(:policy, os_major_version: 9, account: account) }

    subject { policy }

    context 'when content ships per-minor datastreams (hosted)' do
      before do
        allow(SupportedSsg).to receive(:minor_agnostic?).and_return(false)
        allow(subject).to receive(:os_minor_versions).and_return([0, 4])
      end

      it 'supports a minor listed by the policy' do
        expect(subject.supports_minor?(4)).to be(true)
      end

      it 'rejects a minor not listed by the policy' do
        expect(subject.supports_minor?(5)).to be(false)
      end
    end

    context 'when content ships a single minor-0 datastream (IoP)' do
      before { allow(SupportedSsg).to receive(:minor_agnostic?).and_return(true) }

      it 'supports any minor via the wildcard datastream' do
        expect(subject.supports_minor?(7)).to be(true)
      end
    end
  end

  describe '#ref_id' do
    let(:profile) { FactoryBot.create(:profile) }
    let(:policy) { FactoryBot.create(:policy, account: account, profile: profile) }

    subject { policy }

    it 'returns with the correct ref_id' do
      expect(subject.ref_id).to eq(profile.ref_id)
    end

    context 'with autojoin' do
      subject do
        Policy.where.associated(:profile).select(
          described_class.arel_table[Arel.star],
          'profile.ref_id AS profile__ref_id'
        ).find(policy.id)
      end

      # Mock the profile method to fail the test if autojoin doesn't work
      before { allow(subject).to receive(:profile).and_return(nil) }

      it 'returns with the correct ref_id' do
        expect(subject.ref_id).to eq(profile.ref_id)
      end
    end
  end
end
