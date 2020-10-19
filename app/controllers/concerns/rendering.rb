# frozen_string_literal: true

# Rendering logic for all controllers
module Rendering
  extend ActiveSupport::Concern

  included do
    def render_json(model, **args)
      opts = ['index'].include?(action_name) ? metadata : {}
      opts.merge!(include: params[:include].split(',')) if params[:include]
      render({ json: serializer.new(model, opts) }.merge(args))
    end

    def render_error(models, **args)
      render({ json: {
        errors: model_errors(models)
      }, status: :not_acceptable }.merge(args))
    end

    private

    def model_errors(models = [])
      models = [models].flatten
      models.flat_map do |model|
        model.errors.full_messages.map do |error|
          error[0] = error[0].downcase
          "#{model.class.name} #{error}"
        end
      end
    end

    def serializer
      raise NotImplementedError
    end
  end
end
