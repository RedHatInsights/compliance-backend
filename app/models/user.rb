# frozen_string_literal: true

# Represents an individual Insights-Compliance user
class User < ApplicationRecord
  validates:redhat_id, uniqueness: true, presence: true
  validates :username, uniqueness: true, presence: true
  validates_associated :account

  belongs_to :account

  class << self
    def current
      Thread.current[:user]
    end

    def current=(user)
      Thread.current[:user] = user
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    def from_x_rh_identity(identity)
      new(
        account: Account.find_by(
          account_number: identity['account_number']
        ),
        redhat_id: identity['id'] || identity['user_id'],
        redhat_org_id: identity['org_id'],
        email: identity['email'],
        first_name: identity['first_name'] || identity['firstName'],
        last_name: identity['last_name'] || identity['lastName'],
        active: identity['is_active'],
        org_admin: identity['org_admin'],
        locale: identity['locale'] || identity['lang'],
        username: identity['username'] || identity['login'],
        internal: identity['is_internal'] || identity['internal']
      )
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
  end
end
