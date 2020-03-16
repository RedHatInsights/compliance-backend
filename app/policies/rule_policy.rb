# frozen_string_literal: true

# Policies for accessing Rules
class RulePolicy < ApplicationPolicy
  def index?
    record.profiles.pluck(:account_id).include?(user.account_id) ||
      record.canonical?
  end

  def show?
    record.profiles.pluck(:account_id).include?(user.account_id) ||
      record.canonical?
  end

  # Only select Rules belonging to profiles visible by the current user
  # (profile account ID = rule account ID)
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      return Rule.where('false') if user.account_id.blank?

      Rule.includes(:profiles)
          .where(profiles: { account: user.account_id })
          .or(Rule.canonical)
    end
  end
end
