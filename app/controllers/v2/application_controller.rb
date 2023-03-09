# frozen_string_literal: true

module V2
  # base Application controller for APIv2 controllers
  class ApplicationController < ::ActionController::API
    def openapi
      send_file Rails.root.join('swagger/v2/openapi.json')
    end
  end
end
