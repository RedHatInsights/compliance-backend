# frozen_string_literal: true

module V2
  # Generic policies for everything, very restrictive. Any model
  # should be overriding only the methods that would make sense
  # to override.
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    # :nocov:
    def index?
      false
    end
    # :nocov:

    # :nocov:
    def show?
      false
    end
    # :nocov:

    # :nocov:
    def create?
      false
    end
    # :nocov:

    # :nocov:
    def update?
      false
    end
    # :nocov:

    # :nocov:
    def destroy?
      false
    end
    # :nocov:

    alias new? create?
    alias edit? update?

    private

    # :nocov:
    def match_account?
      record.account_id == user.account_id
    end
    # :nocov:

    # Generic scope for all models - just matching the account ID.
    # To be overridden on individual model policies if needed.
    class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        scope.all
      end
    end
  end
end
