# frozen_string_literal: true

module V2
  # Extended merge method that can harmonize table aliases, mainly for pundit scoping
  module MergeWithAlias
    extend ActiveSupport::Concern

    def merge_with_alias(other)
      other = visitor_for_merge(aliases_for_merge).accept(other.where_clause.ast)
      other.to_sql == '' ? self : where(other)
    end

    private

    def aliases_for_merge
      aliases = {}

      # Look up all the defined table aliases in the current scope and feed them into the `aliases` hash
      visitor = ArelVisitor.new do |node|
        aliases[node.table_name] = node.name if node.is_a?(Arel::Nodes::TableAlias)
      end

      visitor.accept(where_clause.ast)
      aliases
    end

    # Iterate over the `other` scope and harmonize its table aliases
    def visitor_for_merge(aliases)
      ArelVisitor.new(copy: true) do |node|
        if node.is_a?(Arel::Table) && aliases.key?(node.name)
          node.alias(aliases[node.name])
        elsif node.is_a?(Arel::Nodes::TableAlias) && aliases.key?(node.left.name)
          node.left.alias(aliases[node.left.name])
        else
          node
        end
      end
    end

    # Loose implementation of the BFS visitor from the historical Rails codebase
    class ArelVisitor < Arel::Visitors::Visitor
      def initialize(copy: false, &block)
        super()
        @block = block
        @copy = copy
      end

      private

      # :nocov:
      def visit(node, *args)
        node = node.dup if @copy
        super
        @block.call(node)
      rescue TypeError => e
        raise [e.message, 'You should implement an alias for the missing method'].join(': ')
      end
      # :nocov:

      def nop(_node); end

      def unary(node)
        expr = visit(node.expr)

        node.expr = expr if @copy
      end

      def binary(node)
        left = visit(node.left)
        right = visit(node.right)

        node.left = left if @copy
        node.right = right if @copy
      end

      def nary(node)
        children = node.children.map { |child| visit(child) }
        node.instance_variable_set(:@children, children) if @copy
      end

      def attribute(node)
        relation = visit(node.relation)
        node.relation = relation if @copy
      end

      alias visit_Arel_Nodes_Equality binary
      alias visit_Arel_Nodes_InfixOperation binary
      alias visit_Arel_Nodes_NotEqual binary

      alias visit_Arel_Nodes_And nary
      alias visit_Arel_Nodes_Or nary
      alias visit_Arel_Nodes_Grouping unary
      alias visit_Arel_Attributes_Attribute attribute

      alias visit_ActiveRecord_Relation_QueryAttribute nop
      alias visit_Arel_Nodes_NamedFunction nop
      alias visit_Arel_Nodes_Quoted nop
      alias visit_Arel_Nodes_TableAlias nop
      alias visit_Arel_Nodes_SqlLiteral nop
      alias visit_Arel_Table nop
    end
  end
end
