# frozen_string_literal: true

module Resolvers
  module Concerns
    # Contains fields and methods related with GraphQL Relay record field
    module Record
      extend ActiveSupport::Concern

      included do
        type "Types::#{self::MODEL_CLASS}".safe_constantize, null: false

        argument :id, String, 'Global ID for Record', required: true
      end

      def resolve(id:)
        ::RecordLoader.for(self.class::MODEL_CLASS).load_by_global_id(id)
      end
    end
  end
end
