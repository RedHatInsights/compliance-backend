# frozen_string_literal: true

FactoryBot.define do
  factory :benchmark, class: Xccdf::Benchmark do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "xccdf_org.ssgproject.content_benchmark_RHEL-#{os_major_version}" }
    sequence(:version) { |n| "100.#{(n / 50).floor}.#{n % 50}" }

    transient do
      os_major_version { '7' }
    end
  end
end
