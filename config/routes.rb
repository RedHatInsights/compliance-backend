# frozen_string_literal: true

Rails.application.routes.draw do
  scope "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}" do
    resources :profiles, only: [:index, :show]
    resources :rule_results, only: [:index]
    resources :systems, only: [:index, :destroy]
    resources :rules, only: [:index, :show]
    mount Rswag::Api::Engine => '/'
    mount Rswag::Ui::Engine => '/'
    get 'openapi' => 'application#openapi'
    post 'graphql' => 'graphql#query'
    if Rails.env.development?
      mount GraphiQL::Rails::Engine, at: "/graphiql",
        graphql_path: "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/graphql"
    end
  end
end
