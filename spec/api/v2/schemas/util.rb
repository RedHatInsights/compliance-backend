# frozen_string_literal: true

module Api
  module V2
    module Schemas
      module Util
        def ref_schema(label)
          { '$ref' => "#/components/schemas/#{label}" }
        end
      end
    end
  end
end
