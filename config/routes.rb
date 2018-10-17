# frozen_string_literal: true

Rails.application.routes.draw do
  resources :profiles, only: [:index]
  mount ActionCable.server => '/cable'
end
