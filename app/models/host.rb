# frozen_string_literal: true

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  scoped_search on: %i[id name account_id]
  scoped_search on: :compliant, ext_method: 'filter_by_compliance',
                only_explicit: true
  scoped_search on: :compliance_score, ext_method: 'filter_by_compliance_score',
                only_explicit: true
  scoped_search on: :has_test_results, ext_method: 'test_results?',
                only_explicit: true, operators: ['=']
  scoped_search relation: :profile_hosts, on: :profile_id
  has_many :rule_results, dependent: :delete_all
  has_many :rules, through: :rule_results, source: :rule
  has_many :profile_hosts, dependent: :destroy
  has_many :test_results, dependent: :destroy
  include SystemLike

  has_many :profiles, through: :profile_hosts, source: :profile

  validates :name, presence: true

  class << self
    def filter_by_compliance(_filter, operator, value)
      ids = Host.includes(:profiles).select do |host|
        host.compliant.values.all?(ActiveModel::Type::Boolean.new.cast(value))
      end
      ids = ids.pluck(:id).map { |id| "'#{id}'" }

      return { conditions: '1=0' } if ids.empty?

      operator = operator == '<>' ? 'NOT' : ''
      { conditions: "hosts.id #{operator} IN(#{ids.join(',')})" }
    end

    def filter_by_compliance_score(_filter, operator, score)
      ids = Host.includes(:profiles).select do |host|
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
  end
end
