# frozen_string_literal: true

module V2
  # Model for SCAP policies
  class Policy < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_policies
    self.primary_key = :id

    belongs_to :profile, class_name: 'V2::Profile'
    has_one :security_guide, through: :profile, class_name: 'V2::SecurityGuide'
    has_many :tailorings, class_name: 'V2::Tailoring', dependent: :destroy
    belongs_to :account

    validates :account, presence: true
    validates :profile, presence: true
    validates :title, presence: true
    validates :compliance_threshold, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }

    sortable_by :title
    # sortable_by :os_major_version # TODO: this needs to be made compatible with `expand_resource`
    # sortable_by :host_count # TODO: this can be turned on after we have ways to assign hosts
    sortable_by :business_objective
    sortable_by :compliance_threshold

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]

    def os_major_version
      attributes['security_guide__ref_id'].try(:[], SecurityGuide::OS_MAJOR_RE)&.to_i || security_guide.os_major_version
    end

    def profile_title
      attributes['profile__title'] || profile.title
    end

    def ref_id
      attributes['profile__ref_id'] || profile.ref_id
    end
  end
end
