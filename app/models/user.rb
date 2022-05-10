# frozen_string_literal: true

# Represents an individual Insights-Compliance user
class User < ApplicationRecord
  validates :username, uniqueness: { scope: :account_id }, presence: true
  validates_associated :account

  belongs_to :account

  delegate :account_number, to: :account

  def authorized_to?(access_request)
    rbac_permissions.any? do |access|
      Rbac.verify(access.permission, access_request)
    end
  end

  private

  def rbac_permissions
    # FIXME: pass the original raw identity header here somehow
    @rbac_permissions ||= Rbac.load_user_permissions(account.b64_identity)
  end

  class << self
    def current
      Thread.current[:user]
    end

    def current=(user)
      Thread.current[:user] = user
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def from_x_rh_identity(identity)
      new(
        account: Account.find_by(
          account_number: identity['account_number']
        ),
        # redhat_id: identity['id'] || identity['user_id'],
        redhat_org_id: (identity['internal']['org_id'] if identity['internal']),
        email: identity['user']['email'],
        first_name: identity['user']['first_name'],
        last_name: identity['user']['last_name'],
        active: identity['user']['is_active'],
        org_admin: identity['user']['is_org_admin'],
        locale: identity['user']['locale'],
        username: identity['user']['username'],
        internal: identity['user']['is_internal']
      )
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
