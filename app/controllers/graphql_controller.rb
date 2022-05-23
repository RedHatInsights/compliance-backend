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
  end

  rescue_from GraphQL::UnauthorizedError do
    render_error 'You are not authorized to access this action.', status: :forbidden
  end

  private

  def rbac_allowed?
    user.authorized_to?(Rbac::INVENTORY_VIEWER)
  end
end
