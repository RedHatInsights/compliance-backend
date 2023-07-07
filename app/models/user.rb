# frozen_string_literal: true

# Represents an individual Insights-Compliance user
class User < ApplicationRecord
  validates :username, uniqueness: { scope: :account_id }, presence: true
  validates_associated :account

  belongs_to :account

  delegate :org_id, to: :account

  def authorized_to?(access_request)
    return true if ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)

    rbac_permissions.any? do |access|
      Rbac.verify(access.permission, access_request)
    end
  end

  def inventory_groups
    rbac_permissions.each_with_object([]) do |permission, ids|
      next unless Rbac.verify(permission.permission, Rbac::INVENTORY_HOSTS_READ)
      # Empty array on 'resource_definitions' symbolizes a global access to the permitted resource.
      # In such case, the method returns Rbac::ANY and skips parsing of attributeFilter.
      return Rbac::ANY if permission.resource_definitions == []

      permission.resource_definitions.each do |filter|
        next unless valid_inventory_groups_definition?(filter[:attributeFilter])

        ids.append(*inventory_groups_definition_value(filter[:attributeFilter]))
      end
    end
  end

  private

  def valid_inventory_groups_definition?(definition)
    definition[:value].instance_of?(Array) &&
      definition[:operation] == 'in' &&
      definition[:key] == 'group.id'
  end

  def inventory_groups_definition_value(definition)
    # Received '[nil]' symbolizes access to ungrouped entries.
    # In output represtented with an empty array.
    definition[:value].map { |dv| dv || [] }
  end

  def rbac_permissions
    @rbac_permissions ||= Rbac.load_user_permissions(account.identity_header.raw)
  end

  class << self
    def current
      Thread.current[:user]
    end

    def current=(user)
      Thread.current[:user] = user
    end
  end
end
