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
  include Rendering

  ParamType = ActionController::Parameters

  def openapi
    send_file Rails.root.join('swagger/v1/openapi.v3.yaml')
  end

  def pundit_scope
    Pundit.policy_scope(current_user, resource)
  end

  def resource_params
    params.permit(data: ParamType.map(attributes: ParamType.map))
    params.require(:data).require(:attributes)
          .permit(serializer.attributes_to_serialize.keys)
  end

  rescue_from Pundit::NotAuthorizedError do
    render json: { errors: 'You are not authorized to access this action.' },
           status: :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do |error|
    logger.info "#{error.message} (#{error.class})"
    render json: { errors: "#{error.model} not found with ID #{error.id}" },
           status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |error|
    logger.info "#{error.message} (#{error.class})"
    render json: { errors: "Parameter missing: #{error.message}" },
           status: :unprocessable_entity
  end

  rescue_from StrongerParameters::InvalidParameter do |error|
    logger.info "#{error.message} (#{error.class})"
    render json: { errors: error.message },
           status: :unprocessable_entity
  end
end
