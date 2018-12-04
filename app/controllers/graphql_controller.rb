class GraphqlController < ApplicationController
  def query
    result = Schema.execute(params[:query], variables: params[:variables])
    render json: result
  end
end
