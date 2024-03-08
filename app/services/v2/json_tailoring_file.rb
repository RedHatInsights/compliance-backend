# frozen_string_literal: true

module V2
  # A class representing a JSON Tailoring File
  class JsonTailoringFile
    # :nocov:
    def initialize(profile:, rules: {}, set_values: {}, rule_group_ref_ids: [])
      @tailoring = profile
      @rules = rules
      @rule_group_ref_ids = rule_group_ref_ids
      @set_values = set_values
    end

    def output
      Oj.dump('profiles' => [build_profile])
    end

    private

    def build_profile
      {
        'id' => @tailoring.policy.ref_id,
        'title' => @tailoring.profile.title,
        'groups' => build_groups,
        'rules' => build_rules,
        'variables' => build_variables
      }
    end

    def build_groups
      @rule_group_ref_ids.each_with_object({}) do |ref_id, obj|
        obj[ref_id] = { 'evaluate' => true }
      end
    end

    def build_rules
      @rules.each_with_object({}) do |rule, obj|
        obj[rule.ref_id] = { 'evaluate' => rule.selected }
      end
    end

    def build_variables
      # rubocop:disable Style/HashTransformValues
      @set_values.each_with_object({}) do |(ref_id, value), obj|
        obj[ref_id] = { 'value' => value }
      end
      # rubocop:enable Style/HashTransformValues
    end
    # :nocov:
  end
end
