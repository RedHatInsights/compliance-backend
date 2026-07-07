# frozen_string_literal: true

require 'rails_helper'

describe Rule do
  describe '#remediation_issue_id' do
    let(:remediation_available) { true }

    let(:profile) do
      FactoryBot.create(
        :profile,
        ref_id: 'xccdf_org.ssgproject.content_profile_foo'
      )
    end

    let(:rule) do
      FactoryBot.create(
        :rule,
        security_guide: profile.security_guide,
        remediation_available: remediation_available,
        profile_id: profile.id,
        ref_id: 'xccdf_org.ssgproject.content_rule_test'
      )
    end

    subject do
      Rule.with_remediation_context
          .for_profile(profile)
          .find(rule.id)
    end

    it 'builds the id' do
      # The short version of the profile ref_id is used (`foo`), but it only exists
      # in the context of the remediation_issue_id.
      expect(subject.remediation_issue_id).to eq(
        "ssg:#{profile.security_guide.ref_id}|#{profile.security_guide.version}|" \
        "foo|#{rule.ref_id}"
      )
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
