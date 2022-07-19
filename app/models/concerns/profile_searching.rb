# frozen_string_literal: true

# Methods that are related to profile searching
module ProfileSearching
  extend ActiveSupport::Concern

  included do
    scoped_search on: %i[id account_id compliance_threshold
                         external parent_profile_id],
                  only_explicit: true
    scoped_search on: %i[name ref_id]
    scoped_search relation: :assigned_hosts, on: :id, rename: :system_ids
    scoped_search relation: :assigned_hosts, on: :display_name,
                  rename: :system_names
    scoped_search relation: :test_result_hosts, on: :id,
                  rename: :test_result_system_ids
    scoped_search relation: :test_result_hosts, on: :display_name,
                  rename: :test_result_system_names
    scoped_search on: :has_test_results, ext_method: 'test_results?',
                  only_explicit: true, operators: ['=']
    scoped_search on: :has_policy_test_results,
                  ext_method: 'policy_test_results?',
                  only_explicit: true, operators: ['=']
    scoped_search on: :canonical, ext_method: 'canonical?', only_explicit: true,
                  operators: ['=']
    scoped_search on: :has_policy, ext_method: 'policy_search',
                  only_explicit: true, operators: ['=']
    scoped_search on: :os_major_version, ext_method: 'os_major_version_search',
                  only_explicit: true, operators: ['=', '!='],
                  validator: ScopedSearch::Validators::INTEGER
    scoped_search on: :os_minor_version, only_explicit: true,
                  operators: ['=', '!='],
                  validator: ScopedSearch::Validators::INTEGER
    scoped_search on: :ssg_version, ext_method: 'ssg_version_search',
                  only_explicit: true, operators: ['=', '!=']
    scoped_search on: :policy_id, ext_method: 'filter_by_policy',
                  only_explicit: true, operators: ['=']

    scope :ssg_versions, lambda { |ssg_versions|
      joins(:benchmark).where(benchmarks: { version: ssg_versions })
    }
    scope :canonical, lambda { |canonical = true|
      canonical && where(parent_profile_id: nil) ||
        where.not(parent_profile_id: nil)
    }
    scope :with_policy, lambda { |with_policy = true|
      with_policy && where.not(policy_id: nil) ||
        where(policy_id: nil)
    }
    scope :external, lambda { |external = true|
      where(external: external)
    }
    scope :has_test_results, lambda { |has_test_results = true|
      test_results = ::TestResult.select(:profile_id).distinct
      has_test_results && where(id: test_results) || where.not(id: test_results)
    }
    scope :has_policy_test_results, lambda { |has_policy_test_results = true|
      # the use of default scope is to bypass Pundit
      # and avoid the situation with bind parameters
      # that must have a different order in the resulting query
      # of a scoped_search
      with_policy_test_results = default_scoped.joins(
        policy: :test_results
      )

      if has_policy_test_results
        where(id: with_policy_test_results)
      else
        where.not(id: with_policy_test_results)
      end
    }
    scope :os_major_version, lambda { |major, equals = true|
      where(benchmark: ::Xccdf::Benchmark.os_major_version(major, equals))
    }
    scope :in_policy, lambda { |policy_or_profile_id|
      return none unless ::UUID.validate(policy_or_profile_id)

      policy_cond = { policy_id: policy_or_profile_id }
      profile_cond = {
        policy: {
          profiles_policies: {
            id: policy_or_profile_id
          }
        }
      }

      search = left_outer_joins(policy: :profiles)
      search.where(id: policy_or_profile_id)
            .or(search.where(policy_cond))
            .or(search.where(profile_cond))
            .distinct
    }
  end

  # class methods for profile searching
  module ClassMethods
    def first_by_os_minor_version_preferred(os_minor_version)
      where(os_minor_version: ['', os_minor_version])
        .order(:os_minor_version)
        .last
    end

    def policy_search(_filter, _operator, value)
      profiles = ::Profile.with_policy(
        ::ActiveModel::Type::Boolean.new.cast(value)
      )
      { conditions: profiles.arel.where_sql.gsub(/^where /i, '') }
    end

    def canonical?(_filter, _operator, value)
      profiles = ::Profile.canonical(
        ::ActiveModel::Type::Boolean.new.cast(value)
      )
      { conditions: profiles.arel.where_sql.gsub(/^where /i, '') }
    end

    def test_results?(_filter, _operator, value)
      has_test_results = ::ActiveModel::Type::Boolean.new.cast(value)
      profiles = ::Profile.has_test_results(has_test_results)
      { conditions: profiles.arel.where_sql.gsub(/^where /i, '') }
    end

    def policy_test_results?(_filter, _operator, value)
      has_test_results = ::ActiveModel::Type::Boolean.new.cast(value)
      profiles = ::Profile.has_policy_test_results(has_test_results)
      { conditions: profiles.arel.where_sql.gsub(/^where /i, '') }
    end

    def os_major_version_search(_filter, operator, value)
      benchmark_id = ::Profile.arel_table[:benchmark_id]
      benchmarks = ::Xccdf::Benchmark.os_major_version(value, operator == '=')
      { conditions: benchmark_id.in(benchmarks.pluck(:id)).to_sql }
    end

    def ssg_version_search(_filter, operator, value)
      benchmark_id = ::Profile.arel_table[:benchmark_id]
      benchmarks = operator == '=' &&
                   ::Xccdf::Benchmark.where(version: value) ||
                   ::Xccdf::Benchmark.where.not(version: value)
      { conditions: benchmark_id.in(benchmarks.pluck(:id)).to_sql }
    end

    def filter_by_policy(_filter, _operator, policy_or_profile_id)
      # We don't really care which ones is being selected if the parent policy is common
      any_child_profile = Profile.in_policy(policy_or_profile_id).select(:id).limit(1)

      {
        conditions: "profiles.id IN (#{any_child_profile.to_sql})"
      }
    end
  end

  class_methods do
    extend ClassMethods
  end

  private

  def in_account(account, policy, os_minor_version = nil)
    search = Profile.where(account: account, ref_id: ref_id,
                           policy: policy,
                           benchmark_id: benchmark_id)

    if os_minor_version
      search.first_by_os_minor_version_preferred(os_minor_version)
    else
      search.first
    end
  end
end
