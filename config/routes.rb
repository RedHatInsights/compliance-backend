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

      if !Rails.env.production? || ENV.fetch('ENABLE_API_V2', false).present?
        scope 'v2', module: 'v2', as: 'v2' do
          resources :security_guides, only: %i[index show] do
            get :supported_profiles, action: :index, controller: :supported_profiles, on: :collection
            get :rule_tree, on: :member

            resources :value_definitions, only: %i[index show], parents: %i[security_guide]
            resources :rules, only: %i[index show], parents: %i[security_guide]
            resources :rule_groups, only: %i[index show], parents: %i[security_guide]
            resources :profiles, only: %i[index show], parents: %i[security_guide] do
              resources :rules, only: %i[index show], parents: %i[security_guide profiles]
            end
          end

          resources :policies, except: %i[new edit] do
            resources :tailorings, only: %i[index show update], parents: %i[policy] do
              resources :rules, only: %i[index create update destroy], parents: %i[policies tailorings]
              get :tailoring_file, on: :member, defaults: { format: 'xml' }, constraints: { format: /json|xml/ }
            end
            resources :systems, only: %i[index create update destroy], parents: %i[policies]
          end

          resources :systems, only: %i[index show] do
            resources :policies, only: %i[index], parents: %i[systems]
            resources :reports, only: %i[index], parents: %i[systems]
          end
          resources :reports, only: %i[index show destroy] do
            resources :systems, only: %i[index show], parents: %i[reports]
            resources :test_results, only: %i[index show], parents: %i[report] do
              resources :rule_results, only: %i[index], parents: %i[report test_result]
            end
            get :stats, on: :member
          end
        end
      end

      concerns :rest_api_v1
      scope 'v1', as: 'v1' do
        concerns :rest_api_v1
      end

      mount Rswag::Api::Engine => '/',
        as: "#{prefix}/#{Settings.app_name}/rswag_api"
      mount Rswag::Ui::Engine => '/',
        as: "#{prefix}/#{Settings.app_name}/rswag_ui"
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
