# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
module V1
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
