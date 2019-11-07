# frozen_string_literal: true

# Methods that are shared between models created from XCCDF types
module OpenscapParserDerived
  extend ActiveSupport::Concern

  included do
    attr_accessor :op_source
  end
end
