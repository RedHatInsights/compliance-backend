# frozen_string_literal: true

FactoryBot.define do
  factory :v2_report, class: 'V2::Report' do
    to_create do |instance, context|
      policy = FactoryBot.create(
        :v2_policy,
        :for_tailoring,
        title: context.title,
        system_id: context.system_id,
        system_count: context.assigned_system_count,
        os_major_version: context.os_major_version,
        compliance_threshold: context.compliance_threshold,
        business_objective: context.business_objective,
        account: context.account,
        supports_minors: context.supports_minors
      )

      unless context.system_id
        unsupported_systems = policy.systems.first(context.unsupported_system_count)
        compliant_systems = (policy.systems - unsupported_systems).first(context.compliant_system_count)
        other_systems = policy.systems - unsupported_systems - compliant_systems

        unsupported_systems.each do |system|
          FactoryBot.create(
            :v2_test_result,
            system: system,
            account: context.account,
            supported: false,
            score: nil,
            policy_id: policy.id
          )
        end

        compliant_systems.each do |system|
          FactoryBot.create(
            :v2_test_result,
            system: system,
            account: context.account,
            supported: true,
            score_above: context.compliance_threshold,
            policy_id: policy.id
          )
        end

        other_systems.each do |system|
          FactoryBot.create(
            :v2_test_result,
            system: system,
            account: context.account,
            supported: true,
            score_below: context.compliance_threshold,
            policy_id: policy.id
          )
        end
      end

      instance.id = policy.id
      instance.attributes = V2::Policy.find(instance.id).attributes
      instance.reload
    end

    transient do
      account { association :v2_account }
      os_major_version { 7 }
      business_objective { Faker::Hacker.noun }
      compliance_threshold { 90 }
      title { Faker::Lorem.sentence }
      supports_minors { [0] }
      system_id { nil }
      assigned_system_count { 4 }
      compliant_system_count { 1 }
      unsupported_system_count { 2 }
    end
  end
end
