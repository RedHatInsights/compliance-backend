# frozen_string_literal: true

# Policies for accessing PolicyHosts
class PolicyHostPolicy < ApplicationPolicy
  # These two methods are for controller-parity only. As the model is not
  # exposed to the API, they should be never used.
  def index?
    Pundit.policy(user, record.host).index?
  end

  def show?
    Pundit.policy(user, record.host).show?
  end

  # Only show hosts in our user account
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      available_hosts = HostPolicy::Scope.new(user, ::Host).resolve.select(:id)
      scope.where(host_id: available_hosts)
    end
  end
end
