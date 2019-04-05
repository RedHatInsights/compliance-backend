# frozen_string_literal: true

# API for Systems (only Hosts for the moment)
class SystemsController < ApplicationController
  include CsvResponder
  include ActionController::MimeResponds

  def index
    respond_to do |format|
      format.any do
        render json: HostSerializer.new(
          scope_search, metadata(total: scope_search.count)
        )
      end
      format.csv do
        csv_response(scope_search(false), csv_params)
      end
    end
  end

  def destroy
    host = Host.find(params[:id])
    authorize host
    host.destroy
    render HostSerializer.new(host)
  end

  private

  def csv_params
    return column_params_to_host_methods if params[:columns].present?

    %w[name profile_names rules_failed compliance_score last_scanned]
  end

  # Transforms the arguments passed to methods

  # Justification: the method gets long because of the if/end needed to
  # handle the params renaming
  # rubocop:disable Metrics/MethodLength
  def column_params_to_host_methods
    host_methods = params[:columns].gsub(/\s/, '_').split(',').map(&:downcase)
    if host_methods.include?('profile')
      host_methods[host_methods.index('profile')] = 'profile_names'
    end
    if host_methods.include?('profiles')
      host_methods[host_methods.index('profiles')] = 'profile_names'
    end
    if host_methods.include?('compliant')
      host_methods[host_methods.index('compliant')] = 'compliance_score'
    end
    host_methods
  end
  # rubocop:enable Metrics/MethodLength

  def resource
    Host
  end
end
