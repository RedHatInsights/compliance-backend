# frozen_string_literal: true

FactoryBot.define do
  factory :security_guide, class: 'SecurityGuide' do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "xccdf_org.ssgproject.content_benchmark_RHEL-#{os_major_version}" }
    sequence(:version) { |n| "100.#{(n / 50).floor}.#{n % 50}" }
    os_major_version { 7 }

    transient do
      rule_count { 0 }
      profile_count { 0 }
      profile_refs { profile_count.times.map { SecureRandom.hex } }
    end

    after(:create) do |security_guide, ev|
      ev.profile_refs.each do |ref, supports_minors|
        create(:profile, ref_id_suffix: ref, supports_minors: supports_minors, security_guide: security_guide)
      end

      create_list(:rule, ev.rule_count, security_guide: security_guide)

      security_guide.reload # FIXME: remove this after the full remodel
    end
  end
end
