# frozen_string_literal: true

module V2
  # Model for the profile support matrix
  class ProfileOsMinorVersion < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :profile_os_minor_versions

    belongs_to :profile, class_name: 'V2::Profile'
  end
end
