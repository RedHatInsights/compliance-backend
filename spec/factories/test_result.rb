# frozen_string_literal: true

FactoryBot.define do
  factory :v2_test_result, class: 'V2::TestResult' do
    tailoring do
      if policy_id
        V2::Tailoring.find_by!(policy_id: policy_id, os_minor_version: system.os_minor_version)
      else
        association :v2_tailoring
      end
    end

    system { association :system, account: account }
    start_time { 5.minutes.ago }
    end_time { 1.minute.ago }
    score { SecureRandom.rand(score_above.to_f..score_below.to_f) }
    supported { true }

    transient do
      account { FactoryBot.create(:v2_account) }
      score_below { 100 }
      score_above { 0 }
      policy_id { nil }
    end
  end
end
