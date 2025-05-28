# frozen_string_literal: true

FactoryBot.define do
  factory :v2_rule_result, class: 'V2::RuleResult' do
    result { %w[fail pass].sample }

    transient do
      title { nil }
      severity { nil }
      remediation_available { nil }
      precedence { nil }
      identifier { nil }
    end

    after(:create) do |rr, ev|
      attrs = {
        title: ev.title,
        severity: ev.severity,
        remediation_available: ev.remediation_available,
        precedence: ev.precedence,
        identifier: ev.identifier
      }.compact

      rr.rule.update(attrs) if attrs.any?
    end
  end
end
