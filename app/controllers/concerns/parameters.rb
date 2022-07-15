# frozen_string_literal: true

# Reusable parameter checking for all controllers
module Parameters
  extend ActiveSupport::Concern

  ParamType = ActionController::Parameters

  included do
    private

    def relationships_enabled?
      permitted_params.permit(relationships: ParamType.boolean)
                      .with_defaults(relationships: true)[:relationships]
    end

    def include_params
      permitted_params.permit(include: ParamType.regexp(/^[a-zA-Z0-9,_]*$/))[:include]
    end

    def permitted_params
      @permitted_params ||= params
    end
  end
end
