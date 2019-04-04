# frozen_string_literal: true

Rails.application.routes.draw do
  scope "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}" do
    resources :profiles, only: [:index, :show]
    resources :rule_results, only: [:index]
    resources :systems, only: [:index, :destroy]
    resources :rules, only: [:index, :show]
    resources :openshift_connections, only: [:create]
    resources :imagestreams, only: [:create]
    mount Rswag::Api::Engine => '/api-docs'
    mount Rswag::Ui::Engine => '/api-docs'
    mount ActionCable.server => '/cable'
    post 'graphql' => 'graphql#query'
    if Rails.env.development?
      mount GraphiQL::Rails::Engine, at: "/graphiql",
        graphql_path: "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/graphql"
    end
  end
end
