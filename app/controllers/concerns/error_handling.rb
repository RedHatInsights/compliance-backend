# frozen_string_literal: true

# Error handlers for catching any 5xx error and giving them a meaningful message
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotUnique do |error|
      render_error "Duplicate record: #{error.message[/Key \(.+\).+\./]}",
                   status: :conflict
    end

    rescue_from Pundit::NotAuthorizedError do
      render_error 'You are not authorized to access this action.',
                   status: :forbidden
    end

    rescue_from Rbac::AuthorizationError do |error|
      render_error error.message, status: :unauthorized
    end

    rescue_from ActiveRecord::RecordNotFound do |error|
      logger.info "#{error.message} (#{error.class})"
      render_error "#{error.model} not found with ID #{error.id}",
                   status: :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |error|
      logger.info "#{error.message} (#{error.class})"
      if error.record
        render_model_errors(error.record)
      else
        render_error(error.message)
      end
    end

    rescue_from ActionController::ParameterMissing do |error|
      logger.info "#{error.message} (#{error.class})"
      render_error "Parameter missing: #{error.message}",
                   status: :unprocessable_entity
    end

    invalid_parameter_exceptions = [
      ActionDispatch::Http::Parameters::ParseError,
      StrongerParameters::InvalidParameter,
      ActionController::UnpermittedParameters,
      ::Exceptions::InvalidSortingDirection,
      ::Exceptions::InvalidSortingColumn,
      ::Exceptions::InvalidTagEncoding,
      PG::InvalidTextRepresentation,
      RangeError
    ]

    rescue_from(*invalid_parameter_exceptions) do |error|
      logger.info "#{error.message} (#{error.class})"
      render_error error.message,
                   status: :unprocessable_entity
    end

    rescue_from JSONAPI::Serializer::UnsupportedIncludeError do |error|
      message = "Invalid parameter: #{error.message.sub(/ on .*Serializer$/, '')}"
      logger.info "#{message} (#{StrongerParameters::InvalidParameter})"
      render_error message,
                   status: :unprocessable_entity
    end

    rescue_from ScopedSearch::QueryNotSupported do |error|
      message = "Invalid parameter: #{error.message}"
      logger.info "#{message} (#{ScopedSearch::QueryNotSupported})"
      render_error message, status: :unprocessable_entity
    end
  end
end
