# frozen_string_literal: true

module Api
  module V1
    module Schemas
      module Util
        def ref_schema(label)
          { '$ref' => "#/components/schemas/#{label}" }
        end
      end
    end
  end
end
