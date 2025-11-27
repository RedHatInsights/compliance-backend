# frozen_string_literal: true

module V2
  # API for Rule Results
  class RuleResultsController < ApplicationController
    def index
      render_json rule_results
    end
    permission_for_action :index, Rbac::REPORT_READ
    kessel_permission_for_action :index, KesselRbac::REPORT_VIEW

    private

    def rule_results
      @rule_results ||= authorize(fetch_collection)
    end

    def resource
      V2::RuleResult
    end

    def serializer
      V2::RuleResultSerializer
    end

    def expand_resource
      scope = join_parents(pundit_scope, permitted_params[:parents])
      scope.joins(build_rule_join)
           .joins(build_test_result_joins)
           .select(*select_fields)
    end

    def select_fields
      base_fields = [resource.arel_table[Arel.star]]
      association_fields = build_association_fields

      base_fields + association_fields
    end

    def build_rule_join
      rule_join = resource.arel_table
                          .join(V2::Rule.arel_table.alias('rule'), Arel::Nodes::InnerJoin)
                          .on(V2::Rule.arel_table.alias('rule')[:id].eq(resource.arel_table[:rule_id]))
      rule_join.join_sources
    end

    def build_test_result_joins
      { test_result: [:system, { tailoring: { profile: :security_guide } }] }
    end

    def build_association_fields
      dependencies.flat_map do |(association, fields)|
        next [] unless association

        table = arel_table_for_association(association)
        next [] unless table

        fields.map { |field| table[field].as("#{association}__#{field}") }
      end
    end

    def arel_table_for_association(association)
      case association
      when :rule
        V2::Rule.arel_table.alias('rule')
      when :system
        Arel::Table.new(:hosts, as: 'system')
      when :profile
        V2::Profile.arel_table
      when :security_guide
        V2::SecurityGuide.arel_table
      end
    end
  end
end
