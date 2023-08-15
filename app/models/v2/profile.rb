# frozen_string_literal: true

module V2
  # Model for Canonical Profile
  class Profile < ApplicationRecord
    self.table_name = 'canonical_profiles'

    sortable_by :title

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]
    scoped_search on: :ref_id, only_explicit: true, operators: %i[eq ne in notin]

    belongs_to :security_guide, class_name: 'V2::SecurityGuide'

    # FIXME: delete after canonical_profiles becomes a table
    def self.count_by
      :id
    end
  end
end
