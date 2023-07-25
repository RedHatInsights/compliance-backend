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
    @inventory_groups ||= Rbac.load_inventory_groups(rbac_permissions)
  end

  private

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
