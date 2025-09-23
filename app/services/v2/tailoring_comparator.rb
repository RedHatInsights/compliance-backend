# frozen_string_literal: true

module V2
  # Service for comparing rules of a tailoring to a target OS minor version's profile rules
  class TailoringComparator
    class InvalidTargetVersionError < StandardError; end

    def initialize(tailoring, params)
      @tailoring = tailoring
      @selected_rules = tailoring.rules
      @source_rules = tailoring.policy.profile.rules
      @target_rules = tailoring.policy.profile.variant_for_minor(params[:target_os_minor]).rules

      if !params[:target_os_minor].present?
        raise InvalidTargetVersionError, 'Target OS minor version is required'
      end

      @params = params

      validate_filter
      filter_rules
    end

    def compare
      group_rules
      mark_selected

      filter_rules
      sort_comparison
      paginate_comparison

      @comparison
    end

    private

    def filter_rules
      @selected_rules = @selected_rules.where.not(id: @target_rules.pluck(:id)) if @params[:diff_only]

      @selected_rules = @selected_rules.where(title: @params[:filter])
    end

    def sort_comparison
      @comparison = @comparison.sort_by(&:title)
    end

    def paginate_comparison
      @comparison = @comparison.limit(@params[:limit]).offset(@params[:offset])
    end

    def group_rules
      all_rules = [
        @source_rules.map { |rule| [rule, @tailoring.os_minor_version] },
        @target_rules.map { |rule| [rule, @params[:target_os_minor]] }
      ].flatten(1)

      @comparison = all_rules.group_by { |rule, _os_minor_version| rule.ref_id }.map do |_, rule_data|

      end
    end

    def build_rule_version(rule, os_minor_version)
      {
        os_major_version: rule.security_guide.os_major_version,
        os_minor_version: os_minor_version,
        ssg_version: rule.security_guide.version
      }
    end

    def mark_selected
      @comparison.each do |rule|
        rule[:selected] = @selected_rules.include?(rule[:id])
      end
    end

    def validate_filter
      if @params[:filter].present? && !@params[:filter].match('title=')
        raise InvalidFilterError, 'Only title filters are supported'
      end
    end
  end
end
