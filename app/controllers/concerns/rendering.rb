# frozen_string_literal: true

# Rendering logic for all controllers
module Rendering
  extend ActiveSupport::Concern

  included do
    def render_json(model, **args)
      model = model.includes(includes) if index? && includes
      render({ json: serializer.new(model, serializer_opts) }.merge(args))
    end

    def render_error(messages, status: :not_acceptable, **opts)
      messages = [messages].flatten
      render({ json: {
        errors: messages
      }, status: status }.merge(opts))
    end

    def render_model_errors(models, status: :not_acceptable, **opts)
      messages = model_errors(models)
      render_error(messages, status: status, **opts)
    end

    private

    def serializer_opts
      opts = index? ? metadata : {}
      opts.merge!(include: params[:include].split(',')) if params[:include]
      opts.merge!(params: pagination)

      opts
    end

    def index?
      ['index'].include?(action_name)
    end

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

    def includes; end

    def pagination
      {
        limit:
          params[:include_limit].present? ? params[:include_limit].to_i : 10,
        offset:
          params[:include_offset].present? ? params[:include_offset].to_i : 1
      }
    end
  end
end
