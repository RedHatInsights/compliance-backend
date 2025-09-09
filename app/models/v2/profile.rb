# frozen_string_literal: true

module V2
  # Model for Canonical Profile
  class Profile < ApplicationRecord
    include V2::RuleTree

    # FIXME: clean up after the remodel
    self.table_name = :canonical_profiles
    self.primary_key = :id

    indexable_by :ref_id, &->(scope, value) { scope.find_by!(ref_id: value.try(:gsub, '-', '.')) }

    sortable_by :title

    searchable_by :title, %i[like unlike eq ne]
    searchable_by :ref_id, %i[eq ne in notin]

    belongs_to :security_guide
    has_many :profile_rules, class_name: 'V2::ProfileRule', dependent: :destroy
    has_many :rules, through: :profile_rules, class_name: 'V2::Rule'
    has_many :os_minor_versions, class_name: 'V2::ProfileOsMinorVersion', dependent: :destroy
    has_many :rule_groups, through: :security_guide, class_name: 'V2::RuleGroup'

    def variant_for_minor(version)
      profile = find_variant_for_minor(version)
      return profile if profile

      raise ::Exceptions::OSMinorVersionNotSupported.new(security_guide.os_major_version, version)
    end

    private

    def find_variant_for_minor(version)
      self.class.unscoped
          .joins(:security_guide, :os_minor_versions)
          .order(self.class.version_to_array(V2::SecurityGuide.arel_table.alias('security_guide')[:version]).desc)
          .find_by(
            ref_id: ref_id,
            security_guide: { os_major_version: security_guide.os_major_version },
            os_minor_versions: { os_minor_version: version }
          )
    end
  end
end
