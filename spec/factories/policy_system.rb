# frozen_string_literal: true

FactoryBot.define do
  factory :v2_policy_system, class: 'V2::PolicySystem' do
    host_id { system_id }
    transient { system_id {} }
  end
end
