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

    def create
      inserts, deletes = V2::PolicySystem.bulk_assign(new_policy_systems, old_policy_systems)

      build_tailorings!

      audit_success("Assigned #{inserts} and unassigned #{deletes} Systems to/from Policy #{policy.id}")
      render_json systems, status: :accepted
    end
    permission_for_action :create, Rbac::POLICY_WRITE
    permitted_params_for_action :create, { ids: ParamType.array(ID_TYPE), policy_id: ID_TYPE, tailoring_id: ID_TYPE }

    def update
      if new_policy_system.save
        render_json system, status: :accepted
        audit_success("Assigned system #{system.id} to policy #{new_policy_system.policy_id}")
      else
        render_model_errors new_policy_system
      end
    end
    permission_for_action :update, Rbac::POLICY_WRITE
    permitted_params_for_action :update, { id: ID_TYPE }

    def destroy
      policy_system = system.policy_systems.find_by!(policy_id: permitted_params[:policy_id])

      policy_system.destroy
      audit_success("Unassigned system #{system.id} from policy #{policy_system.policy_id}")
      render_json system, status: :accepted
    end
    permission_for_action :destroy, Rbac::POLICY_WRITE
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

    def new_policy_systems
      @new_policy_systems ||= begin
        major = policy.os_major_version
        minors = policy.os_minor_versions
        # Filter the passed systems based on what OS versions the policy supports
        items = pundit_scope.where(id: permitted_params[:ids])
                            .os_major_versions(major).os_minor_versions(minors)

        items.map { |item| V2::PolicySystem.new(policy: policy, system: item) }
      end
    end

    def old_policy_systems
      @old_policy_systems ||= begin
        policy.policy_systems.joins(:system).merge_with_alias(pundit_scope(policy.systems))
      end
    end

    def build_tailorings!
      new_policy_systems.uniq { |ps| ps.system.os_minor_version }.map do |record|
        record.run_callbacks(:create)
      end
    end

    def policy
      @policy ||= pundit_scope(V2::Policy).find(permitted_params[:policy_id])
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
