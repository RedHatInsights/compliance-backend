# frozen_string_literal: true

module V2
  # API for Systems (formerly Hosts)
  class SystemsController < ApplicationController
    def index
      render_json systems
    end
    permission_for_action :index, Rbac::SYSTEM_READ

    def show
      render_json system
    end
    permission_for_action :show, Rbac::SYSTEM_READ

    def update
      if new_policy_system.save
        render_json system, status: :accepted
        audit_success("Assigned system #{system.id} to policy #{new_policy_system.policy_id}")
      else
        render_model_errors new_policy_system
      end
    end
    permitted_params_for_action :update, { id: ID_TYPE }

    def destroy
      policy_system = system.policy_systems.find_by!(policy_id: permitted_params[:policy_id])

      policy_system.destroy
      audit_success("Unassigned system #{system.id} from policy #{policy_system.policy_id}")
      render_json system
    end
    permitted_params_for_action :destroy, { id: ID_TYPE }

    private

    def systems
      @systems ||= authorize(fetch_collection)
    end

    def system
      @system ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def new_policy_system
      @new_policy_system ||= begin
        right = pundit_scope.find(permitted_params[:id])
        left = pundit_scope(V2::Policy).where.not(id: right.policies.select(:id))
                                       .find(permitted_params[:policy_id])

        V2::PolicySystem.new(policy: left, system: right)
      end
    end

    def resource
      V2::System
    end

    def serializer
      V2::SystemSerializer
    end

    def extra_fields
      %i[org_id]
    end
  end
end
