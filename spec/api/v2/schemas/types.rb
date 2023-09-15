# frozen_string_literal: true

module Api
  module V2
    module Schemas
      module Types
        extend Util

        UUID = { type: :string, format: :uuid }.freeze
      end
    end
  end
end
