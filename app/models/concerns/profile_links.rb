# frozen_string_literal: true

# Methods that are related to a profile's rule and group tailoring
module ProfileLinks
  extend ActiveSupport::Concern

  included do
    has_many :profile_rules, dependent: :delete_all
    has_many :rules, through: :profile_rules, source: :rule
    has_many :profile_rule_groups, dependent: :delete_all
    has_many :rule_groups, -> { order(:precedence) }, through: :profile_rule_groups, source: :rule_group

    def update_rules(ids: nil, ref_ids: nil)
      update_entities(::ProfileRule.reflect_on_association(:rule), ids: ids, ref_ids: ref_ids)
    end

    def update_rule_groups(ids: nil, ref_ids: nil)
      update_entities(::ProfileRuleGroup.reflect_on_association(:rule_group), ids: ids, ref_ids: ref_ids)
    end

    def update_entities(reflection, **args)
      klass = reflection.active_record
      removed = klass.where(
        profile_id: id,
        reflection.foreign_key => entity_ids_to_destroy(reflection, **args)
      ).destroy_all
      ids_to_add = entity_ids_to_add(reflection, **args)
      imported = klass.import!(ids_to_add.map do |entity_id|
        klass.new(profile_id: id, reflection.foreign_key => entity_id)
      end)

      [imported.ids.count, removed.count]
    end

    private

    def entity_ids_to_add(reflection, **args)
      new_entities(reflection, **args).where.not(id: send(reflection.foreign_key.pluralize)).pluck(:id)
    end

    def entity_ids_to_destroy(reflection, **args)
      send(reflection.foreign_key.pluralize) - new_entities(reflection, **args).pluck(:id)
    end

    def new_entities(reflection, ids:, ref_ids:)
      bm_entities = benchmark.send(reflection.plural_name).select(:id)

      rel = if ids
              bm_entities.where(id: ids)
            elsif ref_ids
              bm_entities.where(ref_id: ref_ids)
            end

      rel&.any? ? rel : bm_entities.where(id: parent_profile_entity_ids(reflection))
    end

    def parent_profile_entity_ids(reflection)
      parent_profile.try(reflection.plural_name)&.select(:id) || []
    end
  end
end
