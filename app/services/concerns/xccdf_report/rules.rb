# frozen_string_literal: true

# Mimics openscap-ruby Rule interface
class RuleOscapObject
  attr_accessor :id, :title, :rationale, :description, :severity
end

module XCCDFReport
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      def rule_ids
        test_result_node.search('rule-result').map { |rr| rr.attributes['idref'].value }
      end

      def create_rule_oscap_object(rule)
        rule_oscap = RuleOscapObject.new
        rule_oscap.id = rule.attributes['id'].value
        rule_oscap.severity = rule.attributes['severity'].value
        rule_oscap.title = rule.search('title').first.children.first.text
        rule_oscap.description = rule.search('description').first
                                     .children.map(&:text).join.delete!("\n")
        rule_oscap.rationale = rule.search('rationale').first
                                   .children.map(&:text).join.delete!("\n")
        rule_oscap
      end

      def rule_objects
        return @rule_objects if @rule_objects.present?

        @rule_objects ||= @report_xml.search('Rule').map do |rule|
          create_rule_oscap_object(rule)
        end
      end

      def rules_already_saved
        return @rules_already_saved if @rules_already_saved.present?

        @rules_already_saved = Rule.select(:id, :ref_id)
                                   .where(ref_id: rule_objects.map(&:id))
                                   .includes(:profiles)
      end

      def add_profiles_to_old_rules(rules, new_profiles)
        preexisting_profiles = ProfileRule.select(:profile_id)
                                          .where(rule_id: rules.pluck(:id))
                                          .pluck(:profile_id).uniq
        rules.find_each do |rule|
          new_profiles.each do |profile|
            unless preexisting_profiles.include?(profile.id)
              ProfileRule.create(rule_id: rule.id, profile_id: profile.id)
            end
          end
        end
      end

      def new_rules
        ref_ids = rules_already_saved.pluck(:ref_id)
        rule_objects.reject do |rule|
          ref_ids.include? rule.id
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
