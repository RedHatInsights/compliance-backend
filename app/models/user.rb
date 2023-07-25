# frozen_string_literal: true

# Represents an individual Insights-Compliance user
class User < ApplicationRecord
  validates :username, uniqueness: { scope: :account_id }, presence: true
  validates_associated :account

  belongs_to :account

  delegate :org_id, :cert_authenticated?, to: :account

  def authorized_to?(access_request)
    return true if rbac_disabled?

    rbac_permissions.any? do |access|
      Rbac.verify(access.permission, access_request)
    end
  end

  def inventory_groups
    # No need to fetch inventory groups if the RBAC feature is globally disabled
    return Rbac::ANY if rbac_disabled?
    # No groups should be available when using certificate authentication
    return [] if cert_authenticated?

    @inventory_groups ||= Rbac.load_inventory_groups(rbac_permissions)
  end

  private

  def rbac_permissions
    @rbac_permissions ||= Rbac.load_user_permissions(account.identity_header.raw)
  end

  def rbac_disabled?
    ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)
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
