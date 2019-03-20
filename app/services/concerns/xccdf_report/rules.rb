# frozen_string_literal: true

module XCCDFReport
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      def rule_ids
        test_result.rr.keys
      end

      def rule_objects
        return @rule_objects if @rule_objects.present?

        @rule_objects ||= @benchmark.items.select do |_, v|
          v.is_a?(OpenSCAP::Xccdf::Rule)
        end
        @rule_objects = @rule_objects.map { |rule| rule[1] }
      end

      def rules_already_saved
        return @rules_already_saved if @rules_already_saved.present?

        @rules_already_saved = Rule.where(ref_id: rule_objects.map(&:id))
                                   .includes(:profiles)
      end

      def add_profiles_to_old_rules(rules, new_profiles)
        rules.each do |rule|
          new_profiles.each do |profile|
            rule.profiles << profile unless rule.profiles.include?(profile)
          end
        end
      end

      def new_rules
        rule_objects.reject do |rule|
          rules_already_saved.map(&:ref_id).include? rule.id
        end
      end

      def save_rules
        new_profiles = Profile.where(ref_id: profiles.keys)
        add_profiles_to_old_rules(rules_already_saved, new_profiles)
        Rule.import(
          new_rules.each_with_object([]) do |rule, new_rules|
            new_rule = Rule.new(profiles: new_profiles).from_oscap_object(rule)
            new_rules << new_rule
          end, recursive: true
        )
      end
    end
  end
end
