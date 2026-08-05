# frozen_string_literal: true

# Builds optimized Arel INNER JOIN nodes from a trie of association reflection chains.
# Merges shared intermediate associations into a single join, aliasing each joined table
# by its association name to preserve the alias contract used by select_fields,
# searchable_by/sortable_by, and merge_with_alias.
module JoinBuilder
  extend ActiveSupport::Concern

  private

  # Builds a trie (prefix tree) from the reflection chains of all requested associations.
  # Shared intermediate associations collapse into a single node.
  def build_join_trie(model, associations)
    trie = {}

    associations.each do |assoc|
      chain = association_chain(model, assoc)
      node = trie
      chain.each { |step| node = (node[step] ||= {}) }
    end

    trie
  end

  # Resolves the full through-chain for an association by walking through_reflection
  # recursively. Returns the chain ordered from source to target.
  def association_chain(model, assoc)
    ref = model.reflect_on_association(assoc)
    return [assoc] unless ref.through_reflection?

    association_chain(model, ref.through_reflection.name) + [assoc]
  end

  # Walks the trie depth-first and emits Arel INNER JOIN nodes with association-name aliases.
  def emit_arel_joins(trie, model, source_table, already_joined_set)
    trie.flat_map do |assoc_name, children|
      source_ref = resolve_source_reflection(model, assoc_name)
      target_table = Arel::Table.new(source_ref.klass.table_name).alias(assoc_name.to_s)
      join = if already_joined_set.include?(assoc_name)
               []
             else
               [build_arel_join_node(source_ref, source_table, target_table)]
             end

      join + emit_arel_joins(children, source_ref.klass, target_table, already_joined_set)
    end
  end

  def resolve_source_reflection(model, assoc_name)
    ref = model.reflect_on_association(assoc_name)
    ref.through_reflection? ? ref.source_reflection : ref
  end

  def build_arel_join_node(ref, source_table, target_table)
    source_table.create_join(
      target_table,
      source_table.create_on(build_join_condition(ref, source_table, target_table)),
      Arel::Nodes::InnerJoin
    )
  end

  def build_join_condition(ref, source_table, target_table)
    if ref.macro == :belongs_to
      target_table[ref.association_primary_key].eq(source_table[ref.foreign_key])
    else
      target_table[ref.foreign_key].eq(source_table[ref.association_primary_key])
    end
  end
end
