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
    value_overrides { profile.value_overrides }

    transient do
      ref_id { policy.profile.ref_id }
      os_major_version { 7 }
    end

    trait :with_tailored_values do
      value_overrides do
        profile.value_overrides.to_a.sample(profile.value_overrides.count / 2).to_h.each do |k, v|
          # overriding (tailoring) default values
          profile.value_overrides[k] = v + SecureRandom.random_number(100)
        end
      end
    end

    trait :with_mixed_rules do
      rules do
        result = []

        loop do
          # sample of rules under profile
          profile_rules = profile.rules.sample(profile.rules.count / 2)
          # sample of rules under security guide, outside of the profile
          sec_guide_rules_avail = security_guide.rules.reject { |rule| profile_rules.include?(rule) }
          sec_guide_rules = sec_guide_rules_avail.sample(sec_guide_rules_avail.count / 2)

          result = sec_guide_rules + profile_rules
          # Make sure that the randomized result doesn't match the profile tailoring
          break if result.to_set(&:id) != profile.rules.to_set(&:id)
        end

        result
      end
    end

    trait :with_default_rules do
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
end
