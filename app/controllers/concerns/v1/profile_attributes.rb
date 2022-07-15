# frozen_string_literal: true

module V1
  # Helper methods related to profile attributes
  module ProfileAttributes
    extend ActiveSupport::Concern

    ParamType = ActionController::Parameters

    included do
      POLICY_CREATE_ATTRIBUTES = %i[name description
                                    compliance_threshold
                                    business_objective].freeze
      POLICY_UPDATE_ATTRIBUTES = %i[description
                                    compliance_threshold
                                    business_objective].freeze
      ALLOWED_CREATE_ATTRIBUTES = %i[parent_profile_id].freeze

      RELATIONSHIP_TYPE = ParamType.map(
        id: ParamType.string,
        type: ParamType.string
      )

      private

      def policy_create_attributes
        resource_attributes.to_h.slice(*POLICY_CREATE_ATTRIBUTES)
                           .merge(account_id: current_user.account_id)
                           .tap do |attrs|
          if business_objective
            attrs.except! :business_objective
            attrs[:business_objective_id] = business_objective.id
          end
        end
      end

      def profile_create_attributes
        resource_attributes.to_h.slice(*ALLOWED_CREATE_ATTRIBUTES)
                           .merge(account_id: current_user.account_id)
                           .tap do # |attrs|
          parent_profile
        end
      end

      def policy_update_attributes
        policy_update_params.to_h.slice(*POLICY_UPDATE_ATTRIBUTES)
                            .tap do |attrs|
          if business_objective
            attrs.except! :business_objective
            attrs[:business_objective_id] = business_objective.id
          end
        end
      end

      def policy_update_params
        resource_params[:attributes]&.permit(*POLICY_UPDATE_ATTRIBUTES)
      end

      def resource_params
        params.permit(data: ParamType.map(
          attributes: ParamType.map,
          relationships: ParamType.map
        ))
        params.require(:data).permit(attributes: {}, relationships: {})
      end

      def resource_attributes
        resource_params[:attributes]&.permit(ProfileSerializer.attributes_to_serialize.keys)
      end

      def resource_relationships
        resource_params[:relationships]&.permit(relationship_types)
      end

      def new_relationship_ids(model)
        relationship = model.to_s.pluralize.downcase.to_sym
        ids = resource_relationships.to_h.dig(relationship, :data)&.map do |res|
          res[:id]
        end

        # Pundit implicitly returns with an empty array when the input is nil.
        # This is unwanted as it would unassign all the systems...
        ::Pundit.policy_scope(current_user, model).where(id: ids).pluck(:id) unless ids.nil?
      end

      def relationship_types
        ProfileSerializer.relationships_to_serialize.keys.each_with_object({}) do |relationship, h|
          h[relationship] = ParamType.map(
            data: ParamType.array(RELATIONSHIP_TYPE) | RELATIONSHIP_TYPE
          )
        end
      end
    end
  end
end
