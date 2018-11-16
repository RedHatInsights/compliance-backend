# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
class SystemsController < ApplicationController
  def index
    render json: HostSerializer.new(Host.all.to_a)
  end
end
