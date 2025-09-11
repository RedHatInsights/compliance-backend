# frozen_string_literal: true

# Represents an individual Insights-Compliance user
class User < ApplicationRecord
  validates :username, uniqueness: { scope: :account_id }, presence: true
  validates_associated :account

  belongs_to :account

  delegate :org_id, :system_owner_id, :cert_authenticated?, to: :account

  def authorized_to?(access_request)
    return true if rbac_disabled?

    if KesselClient.enabled?
      KesselClient.default_permission_allowed?(access_request)
    else
      rbac_permissions.any? do |access|
        Rbac.verify(access.permission, access_request)
      end
    end
  end

  def inventory_groups
    # No need to fetch inventory groups if the RBAC feature is globally disabled or using CERT_AUTH
    return Rbac::ANY if rbac_disabled? || cert_authenticated?

    if KesselClient.enabled?
      kessel_inventory_groups
    else
      @inventory_groups ||= Rbac.load_inventory_groups(rbac_permissions)
    end
  end

  private

  def rbac_permissions
    @rbac_permissions ||= Rbac.load_user_permissions(account.identity_header.raw)
  end

  def rbac_disabled?
    ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)
  end

  # Kessel-based inventory groups using workspace listing
  def kessel_inventory_groups
    @kessel_inventory_groups ||= begin
      workspace_ids = KesselClient.list_workspaces_with_permission(
        permission: Rbac::INVENTORY_HOSTS_READ,
        user: self
      )

      workspace_ids.empty? ? [] : workspace_ids
    rescue KesselClient::AuthorizationError => e
      Rails.logger.error("Kessel inventory groups failed for user #{id}: #{e.message}")
      []
    end
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
