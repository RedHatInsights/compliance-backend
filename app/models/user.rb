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
  end
end
