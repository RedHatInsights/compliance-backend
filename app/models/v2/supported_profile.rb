# frozen_string_literal: true

module V2
  # Model for the SupportedProfiles view
  class SupportedProfile < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :supported_profiles
    self.primary_key = :id

    scoped_search on: :os_major_version, only_explicit: true, operators: %i[eq ne]

    sortable_by :title
    sortable_by :os_major_version
    sortable_by :os_minor_versions
  end
end
