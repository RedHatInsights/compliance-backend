# frozen_string_literal: true

# Policies for accessing Rules
class RulePolicy < ApplicationPolicy
  def index?
    record.profiles.pluck(:account_id).include? user.account_id
  end

  def show?
    record.profiles.pluck(:account_id).include? user.account_id
  end

  # Only select Rules belonging to profiles visible by the current user
  # (profile account ID = rule account ID)
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      return Rule.where('false') if user.account_id.blank?

      account_rule_ids = ProfileRule.where(
        profile_id: Account.find(user.account_id).profiles.pluck(:id)
      ).pluck(:rule_id)
      scope.where(id: account_rule_ids)
    end
  end
end
