# frozen_string_literal: true

require 'rails_helper'

describe V2::Rule do
  describe '#remediation_issue_id' do
    let(:remediation_available) { true }

    let(:profile) do
      FactoryBot.create(
        :v2_profile,
        ref_id: 'xccdf_org.ssgproject.content_profile_foo'
      )
    end

    let(:rule) do
      FactoryBot.create(
        :v2_rule,
        security_guide: profile.security_guide,
        remediation_available: remediation_available,
        profile_id: profile.id,
        ref_id: 'xccdf_org.ssgproject.content_rule_test'
      )
    end

    subject do
      # As this method is intended to be used from a nested profiles/rule route only, we need
      # trick the model to believe that we are in a controller's context where the required
      # two extra fields are available.
      V2::Rule.joins(:security_guide, :profiles)
              .where(security_guide: { id: rule.security_guide.id }, profiles: { id: profile.id })
              .select(
                described_class.arel_table[Arel.star],
                'security_guide.ref_id AS security_guide__ref_id',
                'profiles.ref_id AS profiles__ref_id'
              ).find(rule.id)
    end

    it 'builds the id' do
      expect(subject.remediation_issue_id).to eq('ssg:rhel7|foo|xccdf_org.ssgproject.content_rule_test')
    end

    context 'with remediation_available=false' do
      let(:remediation_available) { false }

      it 'returns with nil' do
        expect(subject.remediation_issue_id).to be_nil
      end
    end

    context 'with parent profile unavailable' do
      subject { rule }

      it 'fails with an exception' do
        expect { subject.remediation_issue_id }.to raise_error(ArgumentError)
      end
    end
  end
end
