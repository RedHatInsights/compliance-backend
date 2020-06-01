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

    scope :canonical, lambda { |canonical = true|
      canonical && where(parent_profile_id: nil) ||
        where.not(parent_profile_id: nil)
    }
    scope :external, lambda { |external = true|
      where(external: external)
    }
    scope :has_test_results, lambda { |has_test_results = true|
      test_results = TestResult.select(:profile_id).distinct
      has_test_results && where(id: test_results) || where.not(id: test_results)
    }
  end

  class_methods do
    def canonical?(_filter, _operator, value)
      profiles = Profile.canonical(ActiveModel::Type::Boolean.new.cast(value))
      { conditions: profiles.arel.where_sql.gsub(/^where /i, '') }
    end

    def test_results?(_filter, _operator, value)
      has_test_results = ActiveModel::Type::Boolean.new.cast(value)
      profiles = Profile.has_test_results(has_test_results)
      { conditions: profiles.arel.where_sql.gsub(/^where /i, '') }
    end
  end
end
