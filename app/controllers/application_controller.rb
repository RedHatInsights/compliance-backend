# frozen_string_literal: true

# General controller to include all-encompassing behavior
class ApplicationController < ActionController::API
  include Authentication
end
