# frozen_string_literal: true

# Methods that are related to profile tailoring
module ProfileTailoring
  def tailored_rule_ref_ids
    return [] unless tailored?

    (added_rules.map do |rule|
      [rule.ref_id, true] # selected
    end + removed_rules.map do |rule|
      [rule.ref_id, false] # notselected
    end).to_h
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

  def tailoring_valid?
    conflicts, requires = %w[conflicts requires].map do |relationship|
      with_relationships(relationship, rules, hierarchical_rule_groups).map(&:right)
    end

    rules_and_groups = rules | hierarchical_rule_groups
    (requires - rules_and_groups).empty? && (conflicts & rules_and_groups).empty?
  end
end
