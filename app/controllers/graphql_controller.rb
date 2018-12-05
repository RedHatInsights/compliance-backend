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
end
