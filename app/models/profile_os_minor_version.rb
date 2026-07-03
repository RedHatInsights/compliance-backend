# frozen_string_literal: true

# Model for the profile support matrix
class ProfileOsMinorVersion < ApplicationRecord
  # FIXME: clean up after the remodel
  self.table_name = :profile_os_minor_versions

  belongs_to :profile, class_name: 'Profile'
end
