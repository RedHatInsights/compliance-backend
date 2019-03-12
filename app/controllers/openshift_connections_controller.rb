# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
class OpenshiftConnectionsController < ApplicationController
  def create
    openshift_connection = OpenshiftConnection.new(openshift_connection_params)
    if openshift_connection.save
      render json: { message: 'Openshift Connection was saved successfully' },
             status: :ok
    else
      render json: { message: 'Openshift Connection was not saved' },
             status: :unprocessable_entity
    end
  end

  private

  def openshift_connection_params
    params.require(:openshift_connection)
          .permit(:username, :token, :api_url, :registry_api_url)
          .merge(account: User.current.account)
  end
end
