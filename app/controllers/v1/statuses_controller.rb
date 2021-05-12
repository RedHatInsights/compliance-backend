# frozen_string_literal: true

module V1
  # API for Compliance Status
  class StatusesController < ApplicationController
    skip_around_action :authenticate_user

    ARB = ActiveRecord::Base

    def show
      render json: { data: all_statuses }, status: status_return_code
    end

    private

    def all_statuses
      @all_statuses ||= {
        api: api_status
      }
    end

    def status_return_code
      all_statuses.values.all? ? :ok : :internal_server_error
    end

    def api_status
      ensure_db_connection
      ARB.connection.active?
    rescue PG::Error
      false
    end

    def ensure_db_connection
      ARB.establish_connection unless ARB.connection.active?
    end
  end
end
