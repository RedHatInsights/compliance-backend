# frozen_string_literal: true

Rails.application.routes.draw do
  def draw_routes(prefix)
    scope "#{prefix}/#{Settings.app_name}" do
      namespace :v1 do
        resources :benchmarks, only: [:index, :show]
        resources :business_objectives, only: [:index, :show]
        resources :profiles do
          member do
            get 'tailoring_file'
          end
        end
        resources :rule_results, only: [:index]
        resources :systems, only: [:index, :show, :destroy]
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
      resources :systems, controller: 'v1/systems', only: [:index, :show, :destroy]
      resources :rules, controller: 'v1/rules', only: [:index, :show]
      mount Rswag::Api::Engine => '/',
        as: "#{prefix}/#{Settings.app_name}/rswag_api"
      mount Rswag::Ui::Engine => '/',
        as: "#{prefix}/#{Settings.app_name}/rswag_ui"
      get 'openapi' => 'application#openapi'
      post 'graphql' => 'graphql#query'
      if Rails.env.development?
        mount GraphiQL::Rails::Engine, at: "/graphiql",
          graphql_path: "#{prefix}/#{Settings.app_name}/graphql",
          as: "#{prefix}/#{Settings.app_name}/graphiql"
      end
    end
  end

  draw_routes(Settings.path_prefix)
  draw_routes(Settings.old_path_prefix)
end
