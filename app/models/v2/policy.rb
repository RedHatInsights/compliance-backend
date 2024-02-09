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
    belongs_to :account, class_name: 'Account'

    validates :account, presence: true
    validates :profile, presence: true
    validates :title, presence: true
    validates :compliance_threshold, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }

    sortable_by :title
    sortable_by :os_major_version, 'security_guide.os_major_version'
    # sortable_by :system_count # TODO: this can be turned on after we have ways to assign systems
    sortable_by :business_objective
    sortable_by :compliance_threshold

    searchable_by :title, %i[like unlike eq ne in notin]
    searchable_by :os_major_version, %i[eq ne in notin] do |_key, op, val|
      bind = ['IN', 'NOT IN'].include?(op) ? '(?)' : '?'

      {
        conditions: "security_guide.os_major_version #{op} #{bind}",
        parameter: [val.split.map(&:to_i)]
      }
    end

    def os_major_version
      attributes['security_guide__os_major_version'] || security_guide.os_major_version
    end

    def profile_title
      attributes['profile__title'] || profile.title
    end

    def ref_id
      attributes['profile__ref_id'] || profile.ref_id
    end
  end
end
