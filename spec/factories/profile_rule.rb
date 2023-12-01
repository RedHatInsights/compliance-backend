# frozen_string_literal: true

FactoryBot.define do
  factory :v2_profile_rule, class: 'V2::ProfileRule' do
    profile { association :v2_profile }
    rule { association :v2_rule }
  end
end
