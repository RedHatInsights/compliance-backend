# frozen_string_literal: true

module Types
  # Definition of the BaseObject type in GraphQL
  class BaseObject < GraphQL::Schema::Object
    include GraphQL::FragmentCache::Object

    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField
    implements GraphQL::Types::Relay::Node

    class << self
      def model_class(new_model_class = nil)
        if new_model_class
          @model_class = new_model_class
        else
          @model_class ||= "::#{to_s.demodulize}".safe_constantize
        end
      end

      def authorized?(object, context)
        # Warn the developer if there is a missing RBAC permission for a queried GQL type
        if @rbac_permissions.blank?
          Rails.logger.warn("There is no RBAC enforced on to the #{object.class} GraphQL type!")
          return true
        end

        @rbac_permissions.any? do |permission|
          context[:current_user].authorized_to?(permission)
        end
      end

      def enforce_rbac(*permissions)
        @rbac_permissions = permissions
      end
    end

    protected

    def lookahead_includes(lookahead, object, selects_includes)
      selects_includes.each do |selects, includes|
        object = object.includes(includes) if lookahead.selects?(selects)
      end

      object
    end
  end
end
