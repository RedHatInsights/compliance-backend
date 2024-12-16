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

      scope 'v2', module: 'v2', as: 'v2' do
        resources :security_guides, only: %i[index show] do
          get :supported_profiles, action: :index, controller: :supported_profiles, on: :collection
          get :rule_tree, on: :member
          get :os_versions, on: :collection

          resources :value_definitions, only: %i[index show], parents: %i[security_guide]
          resources :rules, only: %i[index show], parents: %i[security_guide]
          resources :rule_groups, only: %i[index show], parents: %i[security_guide]

          resources :profiles, only: %i[index show], parents: %i[security_guide] do
            get :rule_tree, on: :member, parents: %i[security_guide]

            resources :rules, only: %i[index show], parents: %i[security_guide profiles]
          end
        end

        resources :policies, except: %i[new edit] do
          resources :tailorings, only: %i[index show create update], parents: %i[policy] do
            get :tailoring_file, on: :member, defaults: { format: 'xml' }, constraints: { format: /json|xml|toml/ }
            get :rule_tree, on: :member, parents: %i[policy]

            resources :rules, only: %i[index create update destroy], parents: %i[policies tailorings]
          end

          resources :systems, only: %i[index create update destroy], parents: %i[policies] do
            get :os_versions, on: :collection, parents: %i[policies]
          end
        end

        resources :systems, only: %i[index show] do
          resources :policies, only: %i[index], parents: %i[systems]
          resources :reports, only: %i[index], parents: %i[systems]

          get :os_versions, on: :collection
        end

        resources :reports, only: %i[index show destroy] do
          resources :systems, only: %i[index show], parents: %i[reports] do
            get :os_versions, on: :collection, parents: %i[reports]
          end

          resources :test_results, only: %i[index show], parents: %i[report] do
            resources :rule_results, only: %i[index], parents: %i[report test_result]
            get :os_versions, on: :collection, parents: %i[report]
            get :security_guide_versions, on: :collection, parents: %i[report]
          end

          get :stats, on: :member
          get :os_versions, on: :collection
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
    end
  end

  draw_routes(Settings.path_prefix)
  draw_routes(Settings.old_path_prefix)

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
