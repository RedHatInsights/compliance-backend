# frozen_string_literal: true

FactoryBot.define do
  factory :v2_security_guide, class: 'V2::SecurityGuide' do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "xccdf_org.ssgproject.content_benchmark_RHEL-#{os_major_version}" }
    sequence(:version) { |n| "100.#{(n / 50).floor}.#{n % 50}" }

    transient do
      os_major_version { 7 }
    end

    factory :v2_security_guide_with_profiles do
      transient do
        profile_count { 3 }
        profile_refs { profile_count.times.map { SecureRandom.hex } }
      end

      profiles do
        profile_refs.map do |ref, supports_minors|
          association(:v2_profile, ref_id_suffix: ref, supports_minors: supports_minors)
        end
      end
    end

    after(:create, &:reload) # FIXME: remove this after the full remodel
  end
end
