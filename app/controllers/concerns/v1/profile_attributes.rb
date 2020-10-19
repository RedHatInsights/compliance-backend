# frozen_string_literal: true

module V1
  # Helper methods related to profile attributes
  module ProfileAttributes
    extend ActiveSupport::Concern

    included do
      POLICY_ATTRIBUTES = %i[name description
                             compliance_threshold business_objective].freeze
      ALLOWED_CREATE_ATTRIBUTES = %i[parent_profile_id].freeze

      private

      def policy_create_attributes
        resource_attributes.to_h.slice(*POLICY_ATTRIBUTES)
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
        resource_attributes.to_h.slice(*POLICY_ATTRIBUTES).tap do |attrs|
          if business_objective
            attrs.except! :business_objective
            attrs[:business_objective_id] = business_objective.id
          end
        end
      end
    end
  end
end
