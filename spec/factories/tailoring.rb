# frozen_string_literal: true

FactoryBot.define do
  factory :v2_tailoring, class: 'V2::Tailoring' do
    profile do
      V2::Profile
        .joins(:os_minor_versions)
        .find_by!(
          ref_id: ref_id,
          profile_os_minor_versions: {
            os_minor_version: os_minor_version
          }
        )
    end

    transient do
      ref_id { policy.profile.ref_id }
      value_overrides { profile.value_overrides }
      os_major_version { 7 }
    end

    rules do
      # sample of rules under profile
      profile_rules = profile.rules.sample(profile.rules.count / 2)
      # sample of rules under security guide, outside of the profile
      sec_guide_rules_avail = security_guide.rules.reject { |rule| profile_rules.include?(rule) }
      sec_guide_rules = sec_guide_rules_avail.sample(sec_guide_rules_avail.count / 2)

      sec_guide_rules + profile_rules
    end
  end
end
