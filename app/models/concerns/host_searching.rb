# frozen_string_literal: true

# Methods that are related to host searching
module HostSearching
  extend ActiveSupport::Concern

  NUM_OPERATORS = ['=', '>', '<', '<=', '>=', '!='].freeze

  included do
    scoped_search on: %i[id display_name], only_explicit: true
    scoped_search on: :display_name, rename: :name
    scoped_search on: :os_major_version, ext_method: 'filter_os_major_version',
                  only_explicit: true, operators: ['=', '!=', '^', '!^']
    scoped_search on: :os_minor_version, ext_method: 'filter_os_minor_version',
                  only_explicit: true, operators: ['=', '!=', '^', '!^']
    scoped_search on: :compliant, ext_method: 'filter_by_compliance',
                  only_explicit: true
    scoped_search on: :ssg_version, ext_method: 'filter_by_ssg_version',
                  only_explicit: true, operators: ['=', '!=', '^', '!^']
    scoped_search on: :compliance_score,
                  ext_method: 'filter_by_compliance_score',
                  only_explicit: true
    scoped_search on: :failed_rules_with_severity,
                  ext_method: 'filter_by_failed_rules_severity',
                  only_explicit: true
    scoped_search on: :has_test_results, ext_method: 'test_results?',
                  only_explicit: true, operators: ['=']
    scoped_search relation: :test_results, on: :profile_id
    scoped_search on: :policy_id, ext_method: 'filter_by_policy',
                  only_explicit: true, operators: ['=']
    scoped_search on: :with_results_for_policy_id,
                  ext_method: 'filter_with_results_for_policy',
                  only_explicit: true, operators: ['=']
    scoped_search on: :has_policy, ext_method: 'filter_has_policy',
                  only_explicit: true, operators: ['=']
    scoped_search on: :stale_timestamp,
                  only_explicit: true, operators: ['<', '>']
    scoped_search on: :supported_ssg,
                  ext_method: :filter_by_supported_ssg,
                  only_explicit: true, operators: ['=']
    scoped_search on: :reported,
                  ext_method: :filter_by_reported,
                  only_explicit: true, operators: ['=']

    scope :with_policy, lambda { |with_policy = true|
      with_policy && where(id: ::PolicyHost.select(:host_id)) ||
        where.not(id: ::PolicyHost.select(:host_id))
    }

    scope :with_test_results, lambda { |with_test_results = true|
      with_test_results && where(id: ::TestResult.select(:host_id)) ||
        where.not(id: ::TestResult.select(:host_id))
    }

    scope :with_policies_or_test_results, lambda {
      with_policy.or(with_test_results)
    }

    scope :os_major_version, lambda { |versions, equal = true|
      where(::Host.os_version_query(:major, versions, equal))
    }

    scope :os_minor_version, lambda { |versions, equal = true|
      where(::Host.os_version_query(:minor, versions, equal))
    }
  end

  # class methods for Host searching
  # rubocop:disable Metrics/ModuleLength
  module ClassMethods
    def filter_os_major_version(_filter, operator, value)
      values = value.split(',').map(&:strip)
      hosts = ::Host.os_major_version(values, ['=', 'IN'].include?(operator))
      { conditions: hosts.arel.where_sql.gsub(/^where /i, '') }
    end

    def filter_os_minor_version(_filter, operator, value)
      values = value.split(',').map(&:strip)
      hosts = ::Host.os_minor_version(values, ['=', 'IN'].include?(operator))
      { conditions: hosts.arel.where_sql.gsub(/^where /i, '') }
    end

    def filter_has_policy(_filter, _operator, value)
      hosts = ::Host.with_policy(::ActiveModel::Type::Boolean.new.cast(value))
      { conditions: hosts.arel.where_sql.gsub(/^where /i, '') }
    end

    def filter_with_results_for_policy(_filter, _operator, policy_or_profile_id)
      profiles = profiles_by_id(policy_or_profile_id)

      RequestStore.store['scoped_search_context_profiles'] = profiles

      { conditions: "hosts.id IN (#{
        ::TestResult.where(profile: profiles).select(:host_id).to_sql
      })" }
    end

    def filter_by_policy(_filter, _operator, policy_or_profile_id)
      profiles = profiles_by_id(policy_or_profile_id) + Profile.select('NULL AS id').distinct

      RequestStore.store['scoped_search_context_profiles'] = profiles

      with_policy = with_policy_lookup(policy_or_profile_id).select(:id)
      with_profile = with_external_profile_lookup(policy_or_profile_id)
                     .select(:id)

      {
        conditions: "hosts.id IN (#{with_policy.to_sql})" \
                    " OR hosts.id IN (#{with_profile.to_sql})"
      }
    end

    def filter_by_compliance(_filter, operator, value)
      hosts = compliant_host_ids(value)

      operator = operator == '<>' ? 'NOT' : ''
      { conditions: "hosts.id #{operator} IN(#{hosts.to_sql})" }
    end

    def filter_by_ssg_version(_filter, operator, value)
      profiles = RequestStore.store['scoped_search_context_profiles']
      values = value.split(',').map(&:strip)

      hosts = search_in(
        TestResult.latest.joins(profile: :benchmark).where(profile: profiles).select(:host_id),
        operator,
        { benchmarks: { version: values } }
      )

      { conditions: "hosts.id IN(#{hosts.to_sql})" }
    end

    def filter_by_compliance_score(_filter, operator, score)
      unless NUM_OPERATORS.include?(operator)
        raise ActiveRecord::StatementInvalid
      end

      profiles = RequestStore.store['scoped_search_context_profiles']

      raise ScopedSearch::QueryNotSupported if profiles.nil?

      hosts = ::TestResult.where("score #{operator} ?", score.to_f)
                          .where(profile: profiles)
                          .latest
                          .select('test_results.host_id')

      { conditions: "hosts.id IN(#{hosts.to_sql})" }
    end

    def search_in(base, operator, where)
      ['=', 'IN'].include?(operator) ? base.where(where) : base.where.not(where)
    end

    def filter_by_failed_rules_severity(_filter, operator, value)
      profiles = RequestStore.store['scoped_search_context_profiles']
      raise ScopedSearch::QueryNotSupported if profiles.nil?

      hosts = search_in(
        ::RuleResult.latest(profiles.compact.first.policy_id)
                    .joins(:rule).where(rule_results: { result: RuleResult::FAILED })
                    .distinct.select(:host_id),
        operator,
        { rules: { severity: value.split(',').map(&:strip) } }
      )
      { conditions: "hosts.id IN(#{hosts.to_sql})" }
    end

    def filter_by_supported_ssg(_filter, _operator, value)
      profiles = RequestStore.store['scoped_search_context_profiles']

      raise ScopedSearch::QueryNotSupported if profiles.nil?

      hosts = ::TestResult.where(supported: value, profile: profiles)
                          .latest.select('test_results.host_id')

      { conditions: "hosts.id IN(#{hosts.to_sql})" }
    end

    def filter_by_reported(_filter, _operator, value)
      profiles = RequestStore.store['scoped_search_context_profiles']

      raise ScopedSearch::QueryNotSupported if profiles.nil?

      hosts = ::TestResult.where(profile: profiles)
                          .latest.select('test_results.host_id')

      { conditions: "hosts.id #{value == 'false' ? 'NOT' : ''} IN(#{hosts.to_sql})" }
    end

    def test_results?(_filter, _operator, value)
      hosts = ::Host.with_test_results(
        ::ActiveModel::Type::Boolean.new.cast(value)
      )

      { conditions: hosts.arel.where_sql.gsub(/^where /i, '') }
    end

    private

    def compliant_host_ids(value)
      profiles = RequestStore.store['scoped_search_context_profiles']

      TestResult.latest
                .where(profile: profiles || User.current.account.profiles)
                .joins(profile: :policy)
                .group(:host_id, 'policies.id', 'policies.compliance_threshold')
                .select(:host_id).having('AVG(test_results.score) <= 100')
                .having("
                  AVG(test_results.score)
                  #{to_b(value) ? '>=' : '<'}
                  policies.compliance_threshold
                ")
    end

    def to_b(str)
      ::ActiveModel::Type::Boolean.new.cast(str)
    end

    def with_policy_lookup(policy_or_profile_id)
      policy_cond = { policies: { id: policy_or_profile_id } }
      profile_cond = { policies: { profiles: { id: policy_or_profile_id } } }

      search = joins(policies: :profiles)
      search.where(policy_cond).or(search.where(profile_cond))
    end

    def with_external_profile_lookup(profile_id)
      joins(test_results: :profile).where(
        test_results: {
          profiles: {
            id: profile_id,
            policy_id: nil
          }
        }
      )
    end

    def profiles_by_id(policy_or_profile_id)
      profiles = ::Profile.where(id: policy_or_profile_id)
      profiles.or(::Profile.where(policy_id: policy_or_profile_id))
              .or(::Profile.where(policy_id: profiles.select(:policy_id)))
    end
  end
  # rubocop:enable Metrics/ModuleLength

  class_methods do
    extend ClassMethods
  end
end
