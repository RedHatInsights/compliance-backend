# frozen_string_literal: true

module V2
  # API for System policies
  class SystemPoliciesController < ApplicationController
    def index
      render json: policies
    end

    def show
      render json: policy
    end
  end
end
