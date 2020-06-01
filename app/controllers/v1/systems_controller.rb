# frozen_string_literal: true

module V1
  # API for Systems (only Hosts for the moment)
  class SystemsController < ApplicationController
    def index
      render json: HostSerializer.new(scope_search, metadata)
    end

    def destroy
      host = Host.find(params[:id])
      authorize host
      host.destroy
      render HostSerializer.new(host)
    end

    private

    def resource
      Host
    end
  end
end
