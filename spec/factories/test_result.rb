# frozen_string_literal: true

FactoryBot.define do
  factory :v2_test_result, class: 'V2::TestResult' do
    tailoring do
      if report_id
        V2::Tailoring.find_by!(policy_id: report_id, os_minor_version: system.os_minor_version)
      else
        association :v2_tailoring
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
      account { FactoryBot.create(:v2_account) }
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
          :v2_rule_result,
          rule: FactoryBot.create(
            :v2_rule,
            security_guide: tr.tailoring.security_guide
          ),
          test_result_id: tr.id,
          severity: rr[:severity],
          result: rr[:result]
        )
      end
    end
  end
end
