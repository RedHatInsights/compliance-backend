# frozen_string_literal: true

# Rendering logic for all controllers
module Rendering
  extend ActiveSupport::Concern

  included do
    def render_json(model, **args)
      opts = ['index'].include?(action_name) ? metadata : {}
      render({ json: serializer.new(model, opts) }.merge(args))
    end

    def render_error(model, **args)
      render({ json: {
        errors: model.errors.full_messages
      }, status: :not_acceptable }.merge(args))
    end

    private

    def serializer
      raise NotImplementedError
    end
  end
end
