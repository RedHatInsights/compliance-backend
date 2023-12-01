# frozen_string_literal: true

module V2
  # API for Tailorings
  class TailoringsController < ApplicationController
    def index
      render_json tailorings
    end
    permission_for_action :index, Rbac::POLICY_READ

    def show
      render_json tailoring
    end
    permission_for_action :show, Rbac::POLICY_READ

    private

    def tailorings
      @tailorings ||= authorize(resolve_collection)
    end

    def tailoring
      @tailoring ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::Tailoring
    end

    def serializer
      V2::TailoringSerializer
    end
  end
end
