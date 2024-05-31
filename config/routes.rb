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
          resources :security_guides, only: [:index, :show] do
            get :supported_profiles, action: :index, controller: :supported_profiles, on: :collection
            get :rule_tree, on: :member

            resources :value_definitions, only: [:index, :show], parents: [:security_guide]
            resources :rules, only: [:index, :show], parents: [:security_guide]
            resources :rule_groups, only: [:index, :show], parents: [:security_guide]
            resources :profiles, only: [:index, :show], parents: [:security_guide] do
              resources :rules, only: [:index, :show], parents: [:security_guide, :profiles]
            end
          end

          resources :policies, except: [:new, :edit] do
            resources :tailorings, only: [:index, :show, :update], parents: [:policy] do
              resources :rules, only: [:index, :create, :update, :destroy], parents: [:policies, :tailorings]
              get :tailoring_file, on: :member, :defaults => { :format => 'xml' }, :constraints => { :format => /json|xml/ }
            end
            resources :systems, only: [:index, :create, :update, :destroy], parents: [:policies]
          end

          resources :systems, only: [:index, :show] do
            resources :policies, only: [:index], parents: [:systems]
          end
          resources :reports, only: [:index, :show] do
            resources :systems, only: [:index, :show], parents: [:reports]
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
