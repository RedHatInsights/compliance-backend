# frozen_string_literal: true

# General controller to include all-encompassing behavior
class ApplicationController < ActionController::API
  include ActionController::Helpers
  include Pundit
  include Authentication

  rescue_from Pundit::NotAuthorizedError do
    render json: { errors: 'You are not authorized to access this action.' },
           status: :forbidden
  end
end
