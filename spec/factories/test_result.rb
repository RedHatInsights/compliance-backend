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
    score do
      min = [score_below, score_above].min
      max = [score_below, score_above].max
      min + SecureRandom.random_number(max - min + 1)
    end
    supported { true }

    transient do
      account { FactoryBot.create(:v2_account) }
      score_below { 100 }
      score_above { 0 }
      policy_id { nil }
    end
  end
end
