# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
class SystemsController < ApplicationController
  include CsvResponder
  include ActionController::MimeResponds

  def index
    respond_to do |format|
      format.any do
        render json: HostSerializer.new(scope_search.to_a)
      end
      format.csv do
        csv_response(*csv_params)
      end
    end
  end

  private

  def csv_params
    [scope_search, Host.column_names - %w[created_at updated_at] << 'compliant']
  end

  def scope_search
    return policy_scope(Host) unless params[:search]

    policy_scope(Host).search_for(params[:search])
  end
end
