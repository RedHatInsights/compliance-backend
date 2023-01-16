# frozen_string_literal: true

# Methods that are related to profile tailoring
module ProfileTailoring
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

  def tailored_rule_ref_ids
    return [] unless tailored?

    (added_rules.map do |rule|
      [rule.ref_id, true] # selected
    end + removed_rules.map do |rule|
      [rule.ref_id, false] # notselected
    end).to_h
  end

  def rule_group_ancestor_ref_ids
    base = RuleGroup.where(id: added_rules.map(&:rule_group_id))
    base.or(
      RuleGroup.where(id: base.select(GROUP_ANCESTRY_IDS))
    ).order(:precedence).pluck(:ref_id)
  end

  def tailored?
    !canonical? && (added_rules + removed_rules).any?
  end

  def added_rules
    rules.order(:precedence) - parent_profile.rules
  end

  def removed_rules
    parent_profile.rules - rules
  end

  def update_os_minor_version(version)
    return unless version && os_minor_version.empty?

    Rails.logger.audit_success(%(
      Setting OS minor version #{version} for profile #{id}
    ).gsub(/\s+/, ' ').strip)

    update!(os_minor_version: version)
  end

  def value_overrides_by_ref_id
    ValueDefinition.where(id: value_overrides.keys).each_with_object({}) do |value_definition, overrides|
      overrides[value_definition.ref_id] = value_overrides[value_definition.id]
    end
  end
end
