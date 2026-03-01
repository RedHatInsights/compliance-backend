# frozen_string_literal: true

module V2
  # A class representing a JSON Tailoring File
  class JsonTailoringFile < TailoringFile
    def initialize(profile:, rules: {}, set_values: {}, rule_group_ref_ids: [], **_hsh)
      @tailoring = profile
      @rules = rules
      @rule_group_ref_ids = rule_group_ref_ids
      @set_values = set_values
    end

    def mime
      Mime[:json]
    end

    def extension
      'json'
    end

    def output
      Oj.dump('profiles' => [build_profile])
    end

    def empty?
      !@tailoring.tailored?
    end

    private

    def build_profile
      {
        'id' => @tailoring.policy.ref_id,
        'title' => @tailoring.profile.title,
        'base_profile_id' => @tailoring.profile.ref_id,
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
      @set_values.transform_values do |value|
        { 'value' => value }
      end
    end
  end
end
