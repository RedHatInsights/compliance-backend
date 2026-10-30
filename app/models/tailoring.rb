# frozen_string_literal: true

# Model for profile tailoring
# rubocop:disable Metrics/ClassLength
class Tailoring < ApplicationRecord
  # Wraps Rule with selected flag for transparent rule delegation.
  class SelectedRule < SimpleDelegator
    def initialize(rule, selected)
      super(rule)
      @selected = selected
    end

    attr_reader :selected
  end

  include RuleTree

  GROUP_ANCESTRY_IDS = Arel::Nodes::NamedFunction.new(
    'CAST',
    [
      Arel::Nodes::NamedFunction.new(
        'unnest',
        [
          Arel::Nodes::NamedFunction.new(
            'string_to_array',
            [
              RuleGroup.arel_table[:ancestry],
              Arel::Nodes::Quoted.new('/')
            ]
          )
        ]
      ).as('uuid')
    ]
  )

  indexable_by :os_minor_version, &lambda { |scope, value|
    next unless value.to_s.match?(/\A\d+\z/)

    major = scope.first&.os_major_version
    scope.find_by!(os_minor_version: SupportedSsg.resolve_minor(major, value))
  }

  sortable_by :os_minor_version

  belongs_to :policy, class_name: 'Policy'
  belongs_to :profile, class_name: 'Profile'
  has_one :security_guide, through: :profile, class_name: 'SecurityGuide'
  has_one :account, through: :policy, class_name: 'Account'
  has_one :report, class_name: 'Report', through: :policy, dependent: nil
  has_many :tailoring_rules,
           class_name: 'TailoringRule',
           dependent: :destroy,
           inverse_of: :tailoring
  has_many :rules, class_name: 'Rule', through: :tailoring_rules
  has_many :test_results, class_name: 'TestResult', dependent: :destroy
  has_many :rule_groups, through: :security_guide, class_name: 'RuleGroup'

  searchable_by :os_minor_version, %i[eq ne]

  validates :policy, presence: true
  validates :profile, presence: true
  validates :os_minor_version, numericality: { greater_than_or_equal_to: 0 }, uniqueness: { scope: :policy }
  validate :value_coherence

  after_create do
    data = ProfileRule.where(profile_id: profile).pluck(:rule_id).map do |rule_id|
      TailoringRule.new(tailoring_id: id, rule_id: rule_id)
    end
    TailoringRule.import(data, on_duplicate_key_ignore: true, validate: false)
  end

  def self.for_policy(policy, os_minor_version)
    os_minor_version = SupportedSsg.resolve_minor(policy.os_major_version, os_minor_version)
    profile = policy.profile.variant_for_minor(os_minor_version)
    Tailoring.new(policy: policy, os_minor_version: os_minor_version,
                  profile: profile, value_overrides: profile.value_overrides)
  end

  def os_major_version
    attributes['security_guide__os_major_version'] || try(:security_guide)&.os_major_version
  end

  def security_guide_id
    attributes['profile__security_guide_id'] || try(:profile)&.security_guide_id
  end

  def security_guide_version
    attributes['profile__security_guide_version'] || try(:security_guide)&.version
  end

  def rule_group_ref_ids
    return rule_group_ref_ids_query unless rules_association_loaded?

    groups_by_id = security_guide.rule_groups.index_by(&:id)
    group_ids = collect_group_ancestry_ids
    group_ids.filter_map { |id| groups_by_id[id]&.ref_id }
  end

  def rule_group_ref_ids_query
    base = RuleGroup.where(id: rules_added.reselect(:rule_group_id))
    base.or(RuleGroup.where(id: base.select(GROUP_ANCESTRY_IDS)))
        .pluck(:ref_id)
  end

  def collect_group_ancestry_ids
    rules_added.filter_map(&:rule_group).flat_map do |group|
      [group.id.to_s, *group.ancestry.to_s.split('/')]
    end.uniq
  end

  def tailored?
    rules_added.any? || rules_removed.any? ||
      value_overrides != profile.value_overrides
  end

  def rules_added
    return rules_added_preloaded if rules_association_loaded?

    rules.where.not(id: profile.rules)
         .select(rules.arel_table[Arel.star], AN::True.new.as('selected'))
  end

  def rules_removed
    return rules_removed_preloaded if rules_association_loaded?

    profile.rules.where.not(id: rules).select(rules.arel_table[Arel.star], AN::False.new.as('selected'))
  end

  def value_overrides_by_ref_id
    return value_overrides_by_ref_id_preloaded if security_guide.association(:value_definitions).loaded?

    ValueDefinition.where(id: value_overrides.keys).to_h do |value_definition|
      [value_definition.ref_id, value_overrides[value_definition.id]]
    end
  end

  private

  def rules_association_loaded?
    association(:rules).loaded?
  end

  def rules_added_preloaded
    preloaded_rules(rules, profile.rules, true)
  end

  def rules_removed_preloaded
    preloaded_rules(profile.rules, rules, false)
  end

  def preloaded_rules(source, excluded, selected)
    excluded_ids = excluded.index_by(&:id)
    source.to_a.filter_map do |rule|
      next if excluded_ids.key?(rule.id)

      selected_rule(rule, selected)
    end
  end

  def value_overrides_by_ref_id_preloaded
    value_definitions = security_guide.value_definitions.index_by { |definition| definition.id.to_s }
    value_overrides.each_with_object({}) do |(id, value), result|
      definition = value_definitions[id.to_s]
      # Skip stale overrides referencing deleted definitions
      result[definition.ref_id] = value if definition
    end
  end

  def selected_rule(rule, selected)
    SelectedRule.new(rule, selected)
  end

  def value_coherence
    lookup = security_guide.value_definitions.where(id: value_overrides.keys).select(:id, :value_type).index_by(&:id)

    # Validate override types one by one, also fail if one of the definitions does not exist
    return unless value_overrides.any? { |key, value| !lookup[key]&.validate_value(value) }

    errors.add(:value_overrides, 'Incoherent keys or value types specified')
  end
end
# rubocop:enable Metrics/ClassLength
