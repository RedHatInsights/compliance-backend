# frozen_string_literal: true

# Entrypoint for all GraphQL API queries
class GraphqlController < ApplicationController
  # TODO: Pass a filtered schema for each user, depending on RBAC
  # http://graphql-ruby.org/schema/limiting_visibility.html
  def query
    result = Schema.execute(
      params[:query],
      variables: params[:variables],
      context: { current_user: current_user }
    )
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  rescue_from GraphQL::UnauthorizedError do
    render_error 'You are not authorized to access this action.', status: :forbidden
  end

  private

  def rbac_allowed?
    user.authorized_to?(Rbac::INVENTORY_VIEWER)
  end

  def handle_error_in_development(exc)
    logger.error exc.message
    logger.error exc.backtrace.join("\n")

    render json: {
      errors: [{
        message: exc.message,
        backtrace: exc.backtrace
      }],
      data: {}
    }, status: :internal_server_error
  end
end
