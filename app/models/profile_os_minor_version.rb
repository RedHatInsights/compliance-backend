# frozen_string_literal: true

# Model for the profile support matrix
class ProfileOsMinorVersion < ApplicationRecord
  belongs_to :profile
end
