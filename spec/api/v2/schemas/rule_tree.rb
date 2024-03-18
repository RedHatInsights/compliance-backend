# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module RuleTree
        extend Api::V2::Schemas::Util

        RULE_TREE = {
          type: :array,
          items: {
            oneOf: [
              {
                type: :object,
                properties: {
                  id: ref_schema('id'),
                  type: {
                    type: :string,
                    enum: ['rule_group']
                  },
                  children: ref_schema('rule_tree')
                }
              },
              {
                type: :object,
                properties: {
                  id: ref_schema('id'),
                  type: {
                    type: :string,
                    enum: ['rule']
                  }
                }
              }
            ]
          }
        }.freeze
      end
    end
  end
end
