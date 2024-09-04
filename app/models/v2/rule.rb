# frozen_string_literal: true

# Stores information about rules. This comes from SCAP.
module V2
  # Model for Rules
  class Rule < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_rules
    self.primary_key = :id

    indexable_by :ref_id, &->(scope, value) { scope.find_by!(ref_id: value.try(:gsub, '-', '.')) }

    attr_accessor :op_source

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
    has_many :profile_rules, class_name: 'V2::ProfileRule', dependent: :destroy
    has_many :profiles, through: :profile_rules, source: :profile, class_name: 'V2::Profile'
    has_many :tailoring_rules, class_name: 'V2::TailoringRule', dependent: :destroy
    has_many :tailorings, through: :tailoring_rules, class_name: 'V2::Tailoring'
    has_many :policies, class_name: 'V2::Policy', through: :tailorings
    has_many :fixes, class_name: 'V2::Fix', dependent: :destroy

    sortable_by :title
    sortable_by :severity, sorted_severities
    sortable_by :precedence
    sortable_by :remediation_available

    searchable_by :title, %i[like unlike eq ne]
    searchable_by :severity, %i[eq ne in notin]
    searchable_by :remediation_available, %i[eq]
    searchable_by :rule_group_id, %i[eq]
    searchable_by :identifier_label, %i[eq neq like unlike] do |_key, op, val|
      val = "%#{val}%" if ['ILIKE', 'NOT ILIKE'].include?(op)

      {
        conditions: "v2_rules.identifier->>'label' #{op} ?",
        parameter: [val]
      }
    end

    # This field should be only available for rules that have a remediation available and it
    # is bound to a context of a profile and a security guide. A single rule can belong to one
    # security guide, but it can be assigned to multiple underlying profiles. If the queried
    # rule has a joined profile and security guide with both of their `ref_id` fields selected
    # and aliased with a `tablename__` prefix, the method will utilize these attributes when
    # building the final result. In case these attributes are not available, the method fails.
    def remediation_issue_id
      return nil unless remediation_available

      sg_ref = security_guide__ref_id
      sg_ver = security_guide__version
      profile_ref = self.class.short_ref_id(profiles__ref_id)

      "ssg:#{sg_ref}|#{sg_ver}|#{profile_ref}|#{ref_id}"
    rescue NameError
      raise ArgumentError, 'Missing security guide or profile on the ActiveRecord result'
    end

    def self.short_ref_id(ref_id)
      ref_id.downcase[SHORT_REF_ID_RE] || ref_id
    end

    def short_ref_id
      self.class.short_ref_id(ref_id)
    end

    # rubocop:disable Metrics/ParameterLists
    def self.from_parser(obj, existing: nil, rule_group_id: nil,
                         security_guide_id: nil, precedence: nil, value_checks: nil)
      record = existing || new(ref_id: obj.id, security_guide_id: security_guide_id)

      record.op_source = obj

      record.assign_attributes(title: obj.title, description: obj.description, rationale: obj.rationale,
                               severity: obj.severity, precedence: precedence, rule_group_id: rule_group_id,
                               upstream: false, value_checks: value_checks, identifier: obj.identifier&.to_h,
                               references: obj.references.map(&:to_h), remediation_available: false)

      record
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
