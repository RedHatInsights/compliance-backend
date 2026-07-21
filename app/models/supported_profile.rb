# frozen_string_literal: true

# Model for the SupportedProfiles view
class SupportedProfile < ApplicationRecord
  # Necessary explicit primary key, since SupportedProfile is backed by a view
  self.primary_key = :id

  searchable_by :os_major_version, %i[eq ne]
  searchable_by :title, %i[eq like]
  searchable_by :ref_id, %i[eq]

  sortable_by :title
  sortable_by :os_major_version
  sortable_by :os_minor_versions
end
