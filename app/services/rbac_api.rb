# frozen_string_literal: true

# This class is meant to handle calls to the RBAC light API
class RbacApi
  def initialize(b64_identity)
    @url = URI.parse("#{URI.parse(Settings.rbac_url)}"\
                     "#{ENV['PATH_PREFIX']}/rbac/v1/access/")
    @b64_identity = b64_identity
  end

  def check_user
    begin
      body = JSON.parse(access_check_response.body)
      body['data'].find do |access_check|
        return true if access_check['permission'] == 'compliance:*:*'
      end
    rescue Faraday::ClientError => e
      Rails.logger.info("#{e.message} #{e.response}")
    end

    false
  end

  private

  def access_check_response
    Platform.connection.get(
      @url, { application: 'compliance' },
      X_RH_IDENTITY: @b64_identity
    )
  end
end
