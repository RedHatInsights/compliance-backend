# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  has_many :profile_rules, dependent: :destroy
  has_many :rules, through: :profile_rules, source: :rule
  has_many :profile_hosts, dependent: :destroy
  has_many :hosts, through: :profile_hosts, source: :host

  validates :ref_id, uniqueness: true, presence: true
  validates :name, presence: true
end
