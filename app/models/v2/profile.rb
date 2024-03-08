# frozen_string_literal: true

module V2
  # Model for Canonical Profile
  class Profile < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :canonical_profiles
    self.primary_key = :id

    indexable_by :ref_id, &->(scope, value) { scope.find_by!(ref_id: value.gsub('-', '.')) }

    sortable_by :title

    searchable_by :title, %i[like unlike eq ne in notin]
    searchable_by :ref_id, %i[eq ne in notin]

    belongs_to :security_guide
    has_many :profile_rules, class_name: 'V2::ProfileRule', dependent: :destroy
    has_many :rules, through: :profile_rules, class_name: 'V2::Rule'
    has_many :os_minor_versions, class_name: 'V2::ProfileOsMinorVersion', dependent: :destroy
  end
end
