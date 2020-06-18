# frozen_string_literal: true

Rails.application.routes.draw do
  def draw_routes(prefix)
    scope "#{prefix}/#{ENV['APP_NAME']}" do
      namespace :v1 do
        resources :benchmarks, only: [:index, :show]
        resources :business_objectives, only: [:index, :show]
        resources :profiles do
          member do
            get 'tailoring_file'
          end
        end
        resources :rule_results, only: [:index]
        resources :systems, only: [:index, :destroy]
        resources :rules, only: [:index, :show]
      end
      resources :benchmarks, controller: 'v1/benchmarks', only: [:index, :show]
      resources :business_objectives, controller: 'v1/business_objectives', only: [:index, :show]
      resources :profiles, controller: 'v1/profiles' do
        member do
          get 'tailoring_file'
        end
      end
      resources :rule_results, controller: 'v1/rule_results', only: [:index]
      resources :systems, controller: 'v1/systems', only: [:index, :destroy]
      resources :rules, controller: 'v1/rules', only: [:index, :show]
      mount Rswag::Api::Engine => '/',
        as: "#{prefix}/#{ENV['APP_NAME']}/rswag_api"
      mount Rswag::Ui::Engine => '/',
        as: "#{prefix}/#{ENV['APP_NAME']}/rswag_ui"
      get 'openapi' => 'application#openapi'
      post 'graphql' => 'graphql#query'
      if Rails.env.development?
        mount GraphiQL::Rails::Engine, at: "/graphiql",
          graphql_path: "#{prefix}/#{ENV['APP_NAME']}/graphql",
          as: "#{prefix}/#{ENV['APP_NAME']}/graphiql"
      end
    end
  end

  draw_routes(ENV['PATH_PREFIX'])
  draw_routes(ENV['OLD_PATH_PREFIX'])
end
