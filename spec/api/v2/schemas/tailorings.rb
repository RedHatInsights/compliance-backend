# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      module Tailorings
        extend Api::V2::Schemas::Util

        TAILORING = {
          profile_id: {},
          value_overrides: {},
          os_minor_version: {},
          os_major_version: {}
        }.freeze
      end
    end
  end
end
