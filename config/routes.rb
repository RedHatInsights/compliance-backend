# frozen_string_literal: true
require 'sidekiq/web'

Rails.application.routes.draw do
  def draw_routes(prefix)
    scope "#{prefix}/#{Settings.app_name}" do
      concern :rest_api_v1 do
        scope module: 'v1' do
          resource 'status', only: :show
          resources :benchmarks, only: [:index, :show]
          resources :business_objectives, only: [:index, :show]
          resources :profiles do
            member do
              get 'tailoring_file'
            end
          end
          resources :rule_results, only: [:index]
          resources :value_definitions, only: [:index]
          resources :systems, only: [:index, :show]
          resources :rules, only: [:index, :show]
          resources :supported_ssgs, only: [:index]
        end
      end

      concern :rest_api_v2 do
        scope module: 'v2' do
          resources :reports, only: [:index]
          resources :systems, only: [:index, :show] do
            resources :policies, only: [:index, :show], controller: 'system_policies'
            resources :profiles, only: [:index, :show], controller: 'system_profiles' do
              resources :rules, only: [:index], controller: 'system_profile_rules'
            end
          end
          resources :ssgs, only: [:index, :show] do
            resources :profiles, only: [:index, :show], controller: 'ssg_profiles'
            resources :rules, only: [:index, :show], controller: 'ssg_rules'
            resources :value_definitions, only: [:index], controller: 'value_definitions'
          end
          resources :policies do
            resources :systems, only: [:index, :show, :update], controller: 'policy_systems'
            resources :reports, only: [:index, :show], controller: 'policy_reports'
            resources :profiles, only: [:index, :show], controller: 'policy_profiles' do
              resources :rules, only: [:index], controller: 'policy_profile_rules'
            end
          end

        end
      end

      concerns :rest_api_v1
      scope 'v1', as: 'v1' do
        concerns :rest_api_v1
      end

      concerns :rest_api_v2
      scope 'v2', as: 'v2' do
        concerns :rest_api_v2
      end

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

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
