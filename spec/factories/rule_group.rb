# frozen_string_literal: true

FactoryBot.define do
  factory :v2_rule_group, class: 'V2::RuleGroup' do
    ref_id { "xccdf_org.ssgproject.content_rule_group_#{SecureRandom.hex}" }
    title { Faker::Lorem.sentence }
    rationale { Faker::Lorem.paragraph }
    description { Faker::Lorem.paragraph }
    security_guide { association :v2_security_guide }

    transient do
      parent_count { 0 }
    end

    ancestry do
      if parent_count == 1
        create(:v2_rule_group).id
      elsif parent_count > 1
        parent_group = create(:v2_rule_group, parent_count: parent_count - 1)
        [parent_group.ancestry, parent_group.id].join('/')
      end
    end
  end
end
