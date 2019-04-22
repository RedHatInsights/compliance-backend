# frozen_string_literal: true

# Generic policies for everything, very restrictive. Any model
# should be overriding only the methods that would make sense
# to override.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def match_account?
    record.account_id == user.account_id
  end

  # Generic scope for all models - just matching the account ID.
  # To be overridden on individual model policies if needed.
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def only_matching_account
      return scope.where('1=0') if user.account_id.blank?

      scope.where(account_id: user.account_id)
    end

    def resolve
      scope.all
    end
  end
end
