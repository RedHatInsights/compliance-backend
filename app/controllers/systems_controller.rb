# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
class SystemsController < ApplicationController
  include ActionController::MimeResponds

  def index
    respond_to do |format|
      format.any do
        render json: HostSerializer.new(scope_search, metadata)
      end
    end
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
