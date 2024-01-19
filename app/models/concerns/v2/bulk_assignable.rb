# frozen_string_literal: true

module V2
  # Logic for bulk reassigning entities to other entity
  module BulkAssignable
    extend ActiveSupport::Concern

    included do
      def update_and_bulk_assign(update_map, assoc_model)
        right_reflection = assoc_model.reflect_on_all_associations.last
        right_key = right_reflection.plural_name.to_sym

        if update_map.dig(right_key)
          systems_added, systems_removed = bulk_assign(assoc_model,
                                                       right_reflection.klass.find(update_map.dig(right_key)))
          audit_success("Updated systems assignment on policy #{id}, " \
            "#{systems_added} added, #{systems_removed} removed")
        end

        update(update_map)
      end

      def bulk_assign(assoc_model, right_records)
        imported = removed = 0

        transaction do
          removed = assoc_model.where(model_name.element.to_sym => self).delete_all
          imported = import_in_bulk!(assoc_model, id, right_records).ids.count
        end

        [imported, removed]
      end

      def import_in_bulk!(assoc_model, left_id, right_records)
        left_field, right_field = assoc_model.reflect_on_all_associations.map(&:foreign_key)

        assoc_model.import!(right_records.map do |record|
          { left_field => left_id, right_field => record.id }
        end, all_or_none: true, validate_uniqueness: true)
      end
    end
  end
end
