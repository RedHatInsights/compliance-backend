# frozen_string_literal: true

Rails.application.routes.draw do
  scope '/api/compliance/' do
    resources :profiles, only: [:index, :show]
    resources :rule_results, only: [:index]
    resources :systems, only: [:index]
    resources :rules, only: [:index, :show]
    mount Rswag::Api::Engine => '/api-docs'
    mount Rswag::Ui::Engine => '/api-docs'
    mount ActionCable.server => '/cable'
    post 'graphql' => 'graphql#query'
    if Rails.env.development?
      mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/r/insights/platform/compliance/graphql"
    end
  end
end
