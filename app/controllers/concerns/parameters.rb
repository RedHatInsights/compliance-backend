# frozen_string_literal: true

# Reusable parameter checking for all controllers
module Parameters
  extend ActiveSupport::Concern

  ParamType = ActionController::Parameters

  RELATIONSHIP_TYPE = ParamType.map(
    id: ParamType.string,
    type: ParamType.string
  )

  included do
    def resource_params
      params.permit(data: ParamType.map(
        attributes: ParamType.map,
        relationships: ParamType.map
      ))
      params.require(:data).permit(attributes: {}, relationships: {})
    end

    def resource_attributes
      resource_params[:attributes]&.permit(
        serializer.attributes_to_serialize.keys
      )
    end

    def resource_relationships
      resource_params[:relationships]&.permit(relationship_types)
    end

    private

    def relationship_types
      serializer.relationships_to_serialize.keys
                .each_with_object({}) do |relationship, h|
        h[relationship] = ParamType.map(
          data: ParamType.array(RELATIONSHIP_TYPE) | RELATIONSHIP_TYPE
        )
      end
    end
  end
end
