# frozen_string_literal: true

FactoryBot.define do
  factory :benchmark, class: Xccdf::Benchmark do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    ref_id { "#{SecureRandom.uuid}_RHEL-#{os_major_version}" }
    version { 3.times.map { SecureRandom.rand(10) }.join('.') }

    transient do
      os_major_version { '7' }
    end
  end
end
