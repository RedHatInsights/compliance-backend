# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
class SystemsController < ApplicationController
  def index
    render json: HostSerializer.new(policy_scope(Host).to_a)
  end
end
