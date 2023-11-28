# frozen_string_literal: true

module V2
  # Model for Canonical Profile
  class Profile < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :canonical_profiles
    self.primary_key = :id

    sortable_by :title

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]
    scoped_search on: :ref_id, only_explicit: true, operators: %i[eq ne in notin]

    belongs_to :security_guide
    has_many :profile_os_minor_versions, class_name: 'V2::ProfileOsMinorVersion', dependent: :destroy
  end
end
