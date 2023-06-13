# frozen_string_literal: true

# Reusable parameter checking for all controllers
module ParameterHandling
  extend ActiveSupport::Concern

  ParamType = ActionController::Parameters
  ParamType.action_on_unpermitted_parameters = :raise
  ID_TYPE = ParamType.integer | ParamType.string
  ARRAY_OR_STRING = ParamType.array(ParamType.string) | ParamType.string
  DEFAULT_PERMITTED = StrongerParameters::ControllerSupport::PermittedParameters::DEFAULT_PERMITTED.merge(
    _json: ParamType.nil,
    include: ParamType.regexp(/^[a-zA-Z0-9,_]*$/)
  )

  class_methods do
    attr_accessor :__permitted_params_for_action

    def permitted_params_for_action(action, params)
      self.__permitted_params_for_action ||= {}
      self.__permitted_params_for_action[action] = params
    end
  end

  included do
    permitted_params_for_action :index, {
      relationships: ParamType.boolean,
      self::SEARCH => ParamType.string,
      sort_by: ARRAY_OR_STRING,
      tags: ARRAY_OR_STRING,
      limit: ParamType.integer & ParamType.gt(0) & ParamType.lte(100),
      offset: ParamType.integer & ParamType.gt(0)
    }

    permitted_params_for_action :show, {
      relationships: ParamType.boolean,
      id: ParamType.string
    }

    permitted_params_for_action :create, data: ParamType.map(
      attributes: ParamType.map,
      relationships: ParamType.map
    )

    permitted_params_for_action :update, id: ID_TYPE.required, data: ParamType.map(
      attributes: ParamType.map,
      relationships: ParamType.map
    )

    permitted_params_for_action :destroy, id: ID_TYPE.required

    private

    def relationships_enabled?
      permitted_params.with_defaults(relationships: true)[:relationships]
    end

    def include_params
      permitted_params[:include]
    end

    def permitted_params
      @permitted_params ||= begin
        action_params = self.class.__permitted_params_for_action.try(:[], action_name.to_sym) || {}
        parent_params = ::ApplicationController.__permitted_params_for_action.try(:[], action_name.to_sym) || {}

        params.permit(parent_params.merge(action_params).merge(DEFAULT_PERMITTED))
      end
    end
  end
end
