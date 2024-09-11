# frozen_string_literal: true

# Stores information about rules. This comes from SCAP.
module V2
  # Model for Rules
  class Rule < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_rules
    self.primary_key = :id

    indexable_by :ref_id, &->(scope, value) { scope.find_by!(ref_id: value.try(:gsub, '-', '.')) }

    # rubocop:disable Metrics/AbcSize
    def self.sorted_severities(table = arel_table)
      Arel.sql(
        AN::Case.new.when(
          table[:severity].eq(AN::Quoted.new('high'))
        ).then(3).when(
          table[:severity].eq(AN::Quoted.new('medium'))
        ).then(2).when(
          table[:severity].eq(AN::Quoted.new('low'))
        ).then(1).else(0).to_sql
      )
    end
    # rubocop:enable Metrics/AbcSize

    SHORT_REF_ID_RE = /
      (?<=
        \Axccdf_org\.ssgproject\.content_profile_|
        \Axccdf_org\.ssgproject\.content_rule_|
        \Axccdf_org\.ssgproject\.content_benchmark_
      ).*\z
    /x

    belongs_to :security_guide
    belongs_to :rule_group, class_name: 'V2::RuleGroup', optional: true
    has_many :profile_rules, dependent: :destroy
    has_many :profiles, through: :profile_rules, source: :profile, class_name: 'V2::Profile'
    has_many :tailoring_rules, class_name: 'V2::TailoringRule', dependent: :destroy
    has_many :tailorings, through: :tailoring_rules, class_name: 'V2::Tailoring'
    has_many :policies, class_name: 'V2::Policy', through: :tailorings

    sortable_by :title
    sortable_by :severity, sorted_severities
    sortable_by :precedence
    sortable_by :remediation_available

    searchable_by :title, %i[like unlike eq ne in notin]
    searchable_by :severity, %i[eq ne in notin]
    searchable_by :remediation_available, %i[eq]
    searchable_by :rule_group_id, %i[eq]

    # This field should be only available for rules that have a remediation available and it
    # is bound to a context of a profile and a security guide. A single rule can belong to one
    # security guide, but it can be assigned to multiple underlying profiles. If the queried
    # rule has a joined profile and security guide with both of their `ref_id` fields selected
    # and aliased with a `tablename__` prefix, the method will utilize these attributes when
    # building the final result. In case these attributes are not available, the method fails.
    def remediation_issue_id
      return nil unless remediation_available

      sg_ref = self.class.short_ref_id(security_guide__ref_id).sub('-', '')
      profile_ref = self.class.short_ref_id(profiles__ref_id)

      "ssg:#{sg_ref}|#{profile_ref}|#{ref_id}"
    rescue NameError
      raise ArgumentError, 'Missing security guide or profile on the ActiveRecord result'
    end

    def self.short_ref_id(ref_id)
      ref_id.downcase[SHORT_REF_ID_RE] || ref_id
    end
  end
end
