# frozen_string_literal: true

# Methods that are related to host searching
module HostSearching
  extend ActiveSupport::Concern

  included do
    scoped_search on: %i[name os_major_version os_minor_version]
    scoped_search on: :compliant, ext_method: 'filter_by_compliance',
                  only_explicit: true
    scoped_search on: :compliance_score,
                  ext_method: 'filter_by_compliance_score',
                  only_explicit: true
    scoped_search on: :has_test_results, ext_method: 'test_results?',
                  only_explicit: true, operators: ['=']
    scoped_search relation: :test_results, on: :profile_id
    scoped_search on: :policy_id, ext_method: 'filter_by_policy',
                  only_explicit: true, operators: ['=']
  end

  # class methods for Host searching
  module ClassMethods
    def filter_by_policy(_filter, _operator, policy_or_profile_id)
      with_policy = with_policy_lookup(policy_or_profile_id).select('id')
      with_profile = with_external_profile_lookup(policy_or_profile_id)
                     .select('id')

      {
        conditions: "hosts.id IN (#{with_policy.to_sql})" \
                    " OR hosts.id IN (#{with_profile.to_sql})"
      }
    end

    def filter_by_compliance(_filter, operator, value)
      ids = Host.includes(test_results: :profile).select do |host|
        host.compliant.values.all?(ActiveModel::Type::Boolean.new.cast(value))
      end
      ids = ids.pluck(:id).map { |id| "'#{id}'" }

      if ids.empty?
        return { conditions: '1=0' } if operator == '='
        return { conditions: '1=1' } if operator == '<>'
      end

      operator = operator == '<>' ? 'NOT' : ''
      { conditions: "hosts.id #{operator} IN(#{ids.join(',')})" }
    end

    def filter_by_compliance_score(_filter, operator, score)
      ids = Host.includes(:test_result_profiles).select do |host|
        host.compliance_score.public_send(operator, score.to_f)
      end
      ids = ids.pluck(:id).map { |id| "'#{id}'" }
      return { conditions: '1=0' } if ids.empty?

      { conditions: "hosts.id IN(#{ids.join(',')})" }
    end

    def test_results?(_filter, _operator, value)
      operator = ActiveModel::Type::Boolean.new.cast(value) ? '' : 'NOT'
      host_ids = TestResult.select(:host_id).distinct.where.not(host_id: nil)
      {
        conditions: "hosts.id #{operator} "\
                    "IN(#{host_ids.to_sql})"
      }
    end

    private

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
  end

  class_methods do
    extend ClassMethods
  end
end
