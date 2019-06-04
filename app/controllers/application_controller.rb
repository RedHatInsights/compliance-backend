# frozen_string_literal: true

# General controller to include all-encompassing behavior
class ApplicationController < ActionController::API
  include ActionController::Helpers
  include Pundit
  include Authentication
  include ExceptionNotifierCustomData
  include Metadata
  include Pagination
  include Search

  rescue_from Pundit::NotAuthorizedError do
    render json: { errors: 'You are not authorized to access this action.' },
           status: :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do |error|
    logger.info "#{error.message} (#{error.class})"
    render json: { errors: 'Resource not found' },
           status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |error|
    logger.info "#{error.message} (#{error.class})"
    render json: { errors: "Parameter missing: #{error.message}" },
           status: :unprocessable_entity
  end
end
