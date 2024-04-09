# frozen_string_literal: true

require 'rails_helper'

describe V2::Tailoring do
  describe '#value_overrides_by_ref_id' do
    subject do
      FactoryBot.create(
        :v2_tailoring,
        :with_tailored_values,
        policy: FactoryBot.create(:v2_policy, :for_tailoring, supports_minors: [0]),
        os_minor_version: 0
      )
    end

    it 'indexes overrides by ref_id' do
      expect(subject.value_overrides_by_ref_id).not_to be_empty

      expect(
        subject.security_guide.value_definitions.where(ref_id: subject.value_overrides_by_ref_id.keys)
      ).not_to be_empty
    end
  end
end
