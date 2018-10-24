# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'
  resources :profiles, only: [:index]
  mount ActionCable.server => '/cable'
end
