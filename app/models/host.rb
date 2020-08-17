# frozen_string_literal: true

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  scoped_search on: %i[name os_major_version os_minor_version]
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
  validates :account, presence: true

  def in_inventory
    host_in_inventory(id)
  end

  class << self
    def host_in_inventory(host_id)
      ::HostInventoryAPI.new(
        User.current.account,
        ::Settings.host_inventory_url,
        nil
      ).inventory_host(host_id)
    end

    def find_or_create_hosts_by_inventory_ids(ids)
      ids.map { |id| find_or_create_from_inventory(id) }
    end

    def find_or_create_from_inventory(host_id)
      existing_hosts = ::Pundit.policy_scope(User.current, self)
                               .where(id: host_id).first

      existing_hosts || create_from_inventory(host_id)
    end

    def create_from_inventory(host_id)
      i_host = host_in_inventory(host_id)

      host = find_or_initialize_by(
        id: i_host['id'],
        account_id: User.current.account.id
      ) do |h|
        h.name = i_host['display_name']
      end
      host.save!
      host
    end

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
