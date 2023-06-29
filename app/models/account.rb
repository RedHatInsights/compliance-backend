# frozen_string_literal: true

# Represents a Insights account. An account can be composed of many users
class Account < ApplicationRecord
  has_many :users, dependent: :nullify
  # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :hosts, foreign_key: :org_id, primary_key: :org_id,
                   inverse_of: :account_object
  # rubocop:enable Rails/HasManyOrHasOneDependent
  has_many :profiles, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :business_objectives, through: :policies

  validates :org_id, presence: true, allow_blank: false

  attr_accessor :identity_header

  class << self
    def from_identity_header(identity_header)
      account = Account.find_or_create_by(
        org_id: identity_header.identity['org_id']
      )

      # Set the identity header for further use
      account.identity_header = identity_header

      account
    end
  end

  # rubocop:disable Metrics/MethodLength
  def fake_identity_header
    {
      'identity': {
        'account_number': account_number,
        'org_id': org_id,
        'type': 'User',
        'auth_type': 'basic-auth',
        'user': {
          'username': 'ComplianceSyncJob',
          'email': 'no-reply@redhat.com',
          'first_name': 'Compliance',
          'last_name': 'Team',
          'is_active': true,
          'is_org_admin': true,
          'locale': 'en_US'
        }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  def b64_identity
    Base64.strict_encode64(fake_identity_header.to_json)
  end
end
