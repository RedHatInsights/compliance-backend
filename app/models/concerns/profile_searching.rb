# frozen_string_literal: true

# Methods that are related to profile searching
module ProfileSearching
  extend ActiveSupport::Concern

  included do
    scoped_search on: %i[id name ref_id account_id compliance_threshold
                         external parent_profile_id]
    scoped_search relation: :hosts, on: :id, rename: :system_ids
    scoped_search relation: :hosts, on: :name, rename: :system_names
    scoped_search on: :has_test_results, ext_method: 'test_results?',
                  only_explicit: true, operators: ['=']
    scoped_search on: :canonical, ext_method: 'canonical?', only_explicit: true,
                  operators: ['=']
  end

  class_methods do
    def canonical?(_filter, _operator, value)
      operator = ActiveModel::Type::Boolean.new.cast(value) ? '' : 'NOT'
      { conditions: "parent_profile_id IS #{operator} NULL" }
    end

    def test_results?(_filter, _operator, value)
      operator = ActiveModel::Type::Boolean.new.cast(value) ? '' : 'NOT'
      profile_ids = TestResult.where.not(
        profile_id: nil
      ).select(:profile_id).distinct
      { conditions: "profiles.id #{operator} IN(#{profile_ids.to_sql})" }
    end
  end
end
