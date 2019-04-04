# frozen_string_literal: true

# Class to store all of the attributes related with connecting to Openshift
class OpenshiftConnection < ApplicationRecord
  belongs_to :account
  has_many :imagestreams, dependent: :destroy

  validates :api_url, presence: true
  validates :registry_api_url, presence: true
  validates :username, presence: true
  validates :token, presence: true
  validates_associated :account

  attr_encrypted :token, key: Base64.decode64(Settings.openshift_tokens_secret),
                         encode: true
end
