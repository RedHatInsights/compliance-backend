# frozen_string_literal: true

module V1
  # API for Systems (only Hosts for the moment)
  class SystemsController < ApplicationController
    def index
      render_json scope_search
    end

    def show
      render_json host
    end

    def destroy
      authorize host
      render_json host.destroy
    end

    private

    def host
      @host ||= pundit_scope.find(params[:id])
    end

    def serializer
      HostSerializer
    end

    def resource
      Host
    end
  end
end
