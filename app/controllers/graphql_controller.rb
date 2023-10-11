# frozen_string_literal: true

# Entrypoint for all GraphQL API queries
class GraphqlController < ApplicationController
  QUERY_RE = /\s*((query|mutation) ([a-zA-Z0-9]{1,32}))[ (]/m

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

  # Very primitive way to determine the first occurence of an operation name after
  # a query or a mutation. This does not work with multiplex queries, but as long
  # as the first operation names describe the rest, it should be fine.
  def parse_gql_op
    params[:query]&.match(QUERY_RE).try(:[], 1)
  end

  # Pass the GQL operation name to the payload for Yabeda metrics tagging
  def append_info_to_payload(payload)
    super

    payload[:gql_op] = parse_gql_op
  end

  def rbac_allowed?
    user.authorized_to?(Rbac::INVENTORY_HOSTS_READ)
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
