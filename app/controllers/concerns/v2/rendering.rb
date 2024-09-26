# frozen_string_literal: true

module V2
  # Rendering logic for all controllers
  module Rendering
    extend ActiveSupport::Concern

    included do
      def render_json(model, **args)
        render json: (collection?(model) ? serialize_collection(model) : serialize_individual(model)), **args
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

      def serialize_individual(model)
        Panko::Response.create do |r|
          { data: r.serializer(model, serializer, context: serialization_context) }
        end
      end

      def serialize_collection(model)
        only = permitted_params[:ids_only] ? [:id] : []

        Panko::Response.new(
          data: Panko::ArraySerializer.new(
            model, only: only, each_serializer: serializer, context: serialization_context
          ),
          **metadata(model)
        )
      end

      # The serializer expects the list of relations to determine which `derived_attribute` should be skipped
      def serialization_context
        { joined: (permitted_params[:parents].to_a + resource.one_to_one).uniq }
      end

      def collection?(model)
        !model.is_a?(V2::ApplicationRecord)
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

      # :nocov:
      def serializer
        raise NotImplementedError
      end
      # :nocov:
    end
  end
end
