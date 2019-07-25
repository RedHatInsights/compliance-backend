# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
class SystemsController < ApplicationController
  include CsvResponder
  include ActionController::MimeResponds

  def index
    respond_to do |format|
      format.any do
        render json: HostSerializer.new(scope_search.in_inventory, metadata)
      end
      format.csv do
        csv_response(*csv_params)
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

  def csv_params
    [scope_search, Host.column_names - %w[created_at updated_at] << 'compliant']
  end

  def resource
    Host
  end
end
