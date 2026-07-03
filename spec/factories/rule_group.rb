# frozen_string_literal: true

FactoryBot.define do
  factory :rule_group, class: 'RuleGroup' do
    ref_id { "xccdf_org.ssgproject.content_rule_group_#{SecureRandom.hex}" }
    title { Faker::Lorem.sentence }
    rationale { Faker::Lorem.paragraph }
    description { Faker::Lorem.paragraph }
    security_guide { association :security_guide }

    transient do
      parent_count { 0 }
    end

    ancestry do
      if parent_count == 1
        create(:rule_group).id
      elsif parent_count > 1
        # recursively create a parent(s) to current :rule_group
        parent_group = create(:rule_group, parent_count: parent_count - 1)
        # creating a hierarchy of Rule Groups in format "grandparent/parent/child"
        [parent_group.ancestry, parent_group.id].join('/')
      end
    end
  end
end
