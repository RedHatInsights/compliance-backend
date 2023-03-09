# frozen_string_literal: true

module V2
  # API for Policies
  class PoliciesController < ApplicationController
    def index
      render json: policies
    end

    def show
      render json: policy
    end

    def create
      throw NotImplementedError
    end

    def update
      throw NotImplementedError
    end

    def destroy
      throw NotImplementedError
    end

    def policies
      Policy.all.map(&:id)
    end

    def policy
      Policy.find(params[:id])
    end
  end
end
