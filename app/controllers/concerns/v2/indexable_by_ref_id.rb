# frozen_string_literal: true

module V2
  # Logic for referring to resources with ref_id
  module IndexableByRefId
    extend ActiveSupport::Concern

    included do
      def ref_id_lookup(scope, id)
        if ::UUID.validate(id)
          scope.find(id)
        else
          scope.find_by!(ref_id: to_ref_id(id))
        end
      end

      private

      def to_ref_id(id)
        id.gsub('-', '.')
      end
    end
  end
end
