# frozen_string_literal: true

# Represents a Insights account. An account can be composed of many users
class Account < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :hosts, dependent: :nullify
  has_many :openshift_connections, dependent: :nullify

  validates :account_number, presence: true

  # rubocop:disable Metrics/MethodLength
  def to_identity_header
    {
      'identity': {
        'account_number': account_number,
        'type': 'User',
        'user': {
          'username': 'ComplianceSyncJob',
          'email': 'no-reply@redhat.com',
          'first_name': 'Compliance',
          'last_name': 'Team',
          'is_active': true,
          'is_internal': true,
          'is_org_admin': true,
          'locale': 'en_US'
        }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength
end
