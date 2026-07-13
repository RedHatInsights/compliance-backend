# frozen_string_literal: true

FactoryBot.define do
  factory :test_result, class: 'TestResult' do
    tailoring do
      if report_id
        Tailoring.find_by!(policy_id: report_id, os_minor_version: system.os_minor_version)
      else
        association :tailoring
      end
    end

    system do
      args = {
        display_name: display_name,
        policy_id: report_id,
        os_major_version: os_major_version,
        os_minor_version: os_minor_version,
        groups: groups
      }.compact
      association(:system, account: account, **args)
    end

    report_id { nil }
    start_time { 5.minutes.ago }
    end_time { 1.minute.ago }
    score { SecureRandom.rand(score_above.to_f..score_below.to_f) }
    supported { true }

    transient do
      account { FactoryBot.create(:account) }
      score_below { 100 }
      score_above { 0 }
      display_name { nil }
      os_major_version { nil }
      os_minor_version { nil }
      additional_rule_results { [] }
      groups { nil }
    end

    after(:create) do |tr, ev|
      ev.additional_rule_results.each do |rr|
        FactoryBot.create(
          :rule_result,
          rule: FactoryBot.create(
            :rule,
            security_guide: tr.tailoring.security_guide
          ),
          test_result_id: tr.id,
          severity: rr[:severity],
          result: rr[:result]
        )
      end
    end

    # Used only by dev-env DB seeders (db/seeds.dev.rb).
    # Propagates the :dev_seed trait to the nested system factory so that the
    # system is written directly to hbi.hosts instead of through the read-only
    # inventory.hosts view.
    trait :dev_seed do
      system do
        args = {
          display_name: display_name,
          policy_id: report_id,
          os_major_version: os_major_version,
          os_minor_version: os_minor_version,
          groups: groups
        }.compact
        association(:system, :dev_seed, account: account, **args)
      end
    end
  end
end
