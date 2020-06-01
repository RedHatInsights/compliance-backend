# frozen_string_literal: true

module V1
  # API for Profiles
  class ProfilesController < ApplicationController
    def index
      render_json scope_search.sort_by(&:score)
    end

    def show
      authorize profile
      render json: ProfileSerializer.new(profile)
    end

    def tailoring_file
      return unless profile.tailored?

      send_data XccdfTailoringFile.new(
        profile: profile,
        rule_ref_ids: profile.tailored_rule_ref_ids
      ).to_xml, filename: tailoring_filename, type: Mime[:xml]
    end

    private

    def tailoring_filename
      "#{profile.benchmark.ref_id}__#{profile.ref_id}__tailoring.xml"
    end

    def profile
      @profile ||= Pundit.policy_scope(current_user, resource).find(params[:id])
    end

    def resource
      Profile
    end

    def serializer
      ProfileSerializer
    end
  end
end
