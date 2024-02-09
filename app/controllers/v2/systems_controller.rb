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

    private

    def systems
      @systems ||= authorize(resolve_collection)
    end

    def system
      @system ||= authorize(expand_resource.find(permitted_params[:id]))
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
