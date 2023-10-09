# frozen_string_literal: true

module V2
  # Rendering logic for all controllers
  module Rendering
    extend ActiveSupport::Concern

    included do
      def render_json(model, **args)
        render json: index? ? serialize_collection(model, **args) : serialize_individual(model, **args)
      end

      def render_error(messages, status: :not_acceptable, **opts)
        messages = [messages].flatten
        render({ json: {
          errors: messages
        }, status: status }.merge(opts))
      end

      # FIXME: coverage mask should be removed after the policies endpoint is done
      # :nocov:
      def render_model_errors(models, status: :not_acceptable, **opts)
        messages = model_errors(models)
        render_error(messages, status: status, **opts)
      end
      # :nocov:

      private

      def serialize_individual(model, **args)
        Panko::Response.create do |r|
          {
            data: r.serializer(model, serializer, context: serialization_context),
            **args
          }
        end
      end

      def serialize_collection(model, **args)
        Panko::Response.new(
          data: Panko::ArraySerializer.new(model, each_serializer: serializer, context: serialization_context),
          **metadata,
          **args
        )
      end

      # The serializer expects the list of parents to determine which `derived_attribute` should be skipped
      def serialization_context
        { parents: permitted_params[:parents] }
      end

      def index?
        ['index'].include?(action_name)
      end

      # FIXME: coverage mask should be removed after the policies endpoint is done
      # :nocov:
      def model_errors(models = [])
        models = [models].flatten
        models.flat_map do |model|
          model.errors.full_messages.map do |error|
            error[0] = error[0].downcase
            "#{model.class.name} #{error}"
          end
        end
      end
      # :nocov:

      # :nocov:
      def serializer
        raise NotImplementedError
      end
      # :nocov:
    end
  end
end
