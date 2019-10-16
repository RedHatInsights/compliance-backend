# frozen_string_literal: true

# Definition for the custom compliance GraphQL timeout. Read the graphql-ruby
# documentation to find out what to add or remove here
class ComplianceTimeout < GraphQL::Schema::Timeout
  def handle_timeout(error, query)
    Rails.logger.warn(
      "GraphQL Timeout: #{error.message}: #{query.query_string}"
    )
  end
end
