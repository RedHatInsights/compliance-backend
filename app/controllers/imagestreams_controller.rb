# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
class ImagestreamsController < ApplicationController
  def create
    if new_imagestream.save
      trigger_scans
      render json: { message: 'Imagestream was saved successfully' },
             status: :ok
    else
      render json: { message: 'Imagestream was not saved' },
             status: :unprocessable_entity
    end
  end

  private

  def new_imagestream
    openshift_connection = OpenshiftConnection.new(openshift_connection_params)
    openshift_connection.save
    @imagestream = Imagestream.new(
      imagestream_params.merge(openshift_connection: openshift_connection)
    )
  end

  def trigger_scans
    params['policy'].keys.each do |profile|
      ScanImageJob.perform_later(@imagestream, profile, identity_header)
    end
  end

  def imagestream_params
    params.require(:imagestream).permit(:name)
  end

  def openshift_connection_params
    params.require(:openshift_connection)
          .permit(:username, :token, :api_url, :registry_api_url)
          .merge(account: User.current.account)
  end
end
