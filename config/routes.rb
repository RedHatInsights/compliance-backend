# frozen_string_literal: true

Rails.application.routes.draw do
  scope '/r/insights/platform/compliance/' do
    resources :profiles, only: [:index, :show]
    resources :rule_results, only: [:index]
    resources :systems, only: [:index]
    mount Rswag::Api::Engine => '/api-docs'
    mount Rswag::Ui::Engine => '/api-docs'
    mount ActionCable.server => '/cable'
  end
end
