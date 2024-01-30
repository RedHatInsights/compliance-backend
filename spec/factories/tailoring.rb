# frozen_string_literal: true

FactoryBot.define do
  factory :v2_tailoring, class: 'V2::Tailoring' do
    profile do
      V2::Profile
        .joins(:os_minor_versions)
        .find_by(
          ref_id: ref_id,
          profile_os_minor_versions: {
            os_minor_version: os_minor_version
          }
        )
    end

    transient do
      ref_id { policy.profile.ref_id }
      value_overrides { {} }
      os_major_version { 7 }
    end

    after(:create) do |tailoring, _|
      tailoring.profile.rules.each do |rule|
        FactoryBot.create(
          :v2_tailoring_rule,
          rule: rule,
          tailoring: tailoring
        )
      end
    end
  end
end
