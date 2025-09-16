# frozen_string_literal: true

module V2
  # Service for comparing rules of a tailoring to a target OS minor version's profile rules
  class TailoringRuleComparator
    class InvalidTargetVersionError < StandardError; end

    def initialize(**params)
      source_tailoring = params[:source_tailoring]
      target_os_minor_version = enforce_higher_target_version(
        source_tailoring.os_minor_version,
        params[:target_os_minor_version]
      )

      source_rules, target_rules = find_rules(source_tailoring, target_os_minor_version, params[:diff_only])

      @all_rules = [
        source_rules.map { |rule| [rule, source_tailoring.os_minor_version] },
        target_rules.map { |rule| [rule, target_os_minor_version] }
      ].flatten(1)
    end

    def build_comparison
      @all_rules.group_by { |rule, _os_minor_version| rule.ref_id }.map do |_, rule_data|
        current_rule = rule_data.first[0]
        available_in_versions = rule_data.map { |rule, os_minor_version| build_rule_version(rule, os_minor_version) }

        current_rule.as_json.merge(available_in_versions: available_in_versions)
      end
    end

    private

    def enforce_higher_target_version(source_version, target_version)
      return target_version if target_version > source_version

      raise InvalidTargetVersionError, "Target version #{target_version} is lower than source version #{source_version}"
    end

    def find_rules(source_tailoring, target_os_minor_version, diff_only)
      source_rules = source_tailoring.rules
      target_rules = source_tailoring.policy.profile.variant_for_minor(target_os_minor_version).rules
      source_rules = source_rules.where.not(id: target_rules) if diff_only
      [source_rules, target_rules]
    end

    def build_rule_version(rule, os_minor_version)
      {
        os_major_version: rule.security_guide.os_major_version,
        os_minor_version: os_minor_version,
        ssg_version: rule.security_guide.version
      }
    end
  end
end
