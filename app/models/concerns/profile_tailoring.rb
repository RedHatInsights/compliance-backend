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
    rules - parent_profile.rules
  end

  def removed_rules
    parent_profile.rules - rules
  end
end
