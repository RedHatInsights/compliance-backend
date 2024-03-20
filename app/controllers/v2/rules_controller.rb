# frozen_string_literal: true

module V2
  # API for Rules under Security Guides
  class RulesController < ApplicationController
    def index
      render_json rules
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    def show
      render_json rule
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER

    def update
      if new_tailoring_rule.save
        render_json rule, status: :accepted
        audit_success("Assigned rule #{rule.id} to tailoring #{new_tailoring_rule.tailoring_id}")
      else
        render_model_errors new_tailoring_rule
      end
    end
    permission_for_action :update, Rbac::POLICY_WRITE
    permitted_params_for_action :update, { id: ID_TYPE, policy_id: ID_TYPE, tailoring_id: ID_TYPE }

    def destroy
      tailoring_rule = rule.tailoring_rules.find_by!(tailoring_id: permitted_params[:tailoring_id])

      tailoring_rule.destroy
      audit_success("Unassigned rule #{rule.id} from tailoring #{tailoring_rule.tailoring_id}")
      render_json rule, status: :accepted
    end
    permission_for_action :destroy, Rbac::POLICY_DELETE
    permitted_params_for_action :destroy, { id: ID_TYPE, policy_id: ID_TYPE, tailoring_id: ID_TYPE }

    private

    def rules
      @rules ||= authorize(fetch_collection)
    end

    def rule
      @rule ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def new_tailoring_rule
      @new_tailoring_rule ||= begin
        right = pundit_scope.find(permitted_params[:id])
        left = pundit_scope(V2::Tailoring).where.not(id: right.tailorings.select(:id))
                                          .find(permitted_params[:tailoring_id])

        V2::TailoringRule.new(tailoring: left, rule: right)
      end
    end

    def resource
      V2::Rule
    end

    def serializer
      V2::RuleSerializer
    end
  end
end
