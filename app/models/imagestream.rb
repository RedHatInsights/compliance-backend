# frozen_string_literal: true

# Basic information for Imagestreams
class Imagestream < ApplicationRecord
  include SystemLike

  belongs_to :openshift_connection
  has_many :profile_imagestreams, dependent: :destroy
  has_many :profiles, through: :profile_imagestreams, source: :profile

  validates :name, presence: true, uniqueness: {
    scope: :openshift_connection_id
  }

  def scan
    ScanImageJob.perform_later(self)
  end
end
