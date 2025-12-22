# frozen_string_literal: true

module V2
  # Model for Security Guides
  class SecurityGuide < ApplicationRecord
    include V2::RuleTree

    # FIXME: clean up after the remodel
    self.primary_key = :id
    self.table_name = :security_guides_v2

    has_many :profiles, class_name: 'V2::Profile', dependent: :destroy
    has_many :value_definitions, class_name: 'V2::ValueDefinition', dependent: :destroy
    has_many :rules, class_name: 'V2::Rule', dependent: :destroy
    has_many :rule_groups, class_name: 'V2::RuleGroup', dependent: :destroy

    searchable_by :title, %i[like unlike eq ne]
    searchable_by :version, %i[eq ne]
    searchable_by :ref_id, %i[eq ne in notin]
    searchable_by :os_major_version, %i[eq ne]

    searchable_by :profile_ref_id, %i[eq] do |_key, _op, val|
      ids = ::V2::Profile.unscoped.where(ref_id: val).select(:security_guide_id)

      { conditions: "security_guides_v2.id IN (#{ids.to_sql})" }
    end

    searchable_by :supported_profile, %i[eq] do |_key, _op, val|
      ref_id, os_minor = val.split(':')

      ids = ::V2::Profile.unscoped.joins(:os_minor_versions).where(
        ref_id: ref_id, os_minor_versions: { os_minor_version: os_minor.to_i }
      ).select(:security_guide_id)

      { conditions: "security_guides_v2.id IN (#{ids.to_sql})" }
    end

    sortable_by :title
    sortable_by :version, version_to_array(arel_table[:version])
    sortable_by :os_major_version

    def self.os_versions
      reselect(:os_major_version).distinct.reorder(:os_major_version).map(&:os_major_version)
    end

    def self.from_parser(obj)
      record = find_or_initialize_by(ref_id: obj.id, version: obj.version)
      record.assign_attributes(
        title: obj.title,
        description: obj.description,
        os_major_version: obj.id[/(?<=RHEL-)\d+/]
      )
      record
    end
  end
end
