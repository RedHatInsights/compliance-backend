# frozen_string_literal: true

# Mimics openscap-ruby Rule interface
class RuleOscapObject
  def initialize(rule_xml: nil)
    @rule_xml = rule_xml
  end

  def id
    @id ||= @rule_xml['id']
  end

  def severity
    @severity ||= @rule_xml['severity']
  end

  def title
    @title ||= @rule_xml.at_css('title').children.first.text
  end

  def description
    @description ||= @rule_xml.at_css('description').text.delete("\n")
  end

  def rationale
    @rationale ||= @rule_xml.at_css('rationale').children.text.delete("\n")
  end

  def references
    @references ||= @rule_xml.css('reference').map do |node|
      { href: node['href'], label: node.text }
    end
  end

  def identifier
    @identifier ||= @rule_xml.at_css('ident')&.text
  end

  def identifier_system
    @identifier_system ||= (ident = @rule_xml.at_css('ident')) &&
                           ident['system']
  end
end

module XCCDFReport
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      def rule_objects
        return @rule_objects if @rule_objects.present?

        @rule_objects ||= @report_xml.search('Rule').map do |rule|
          RuleOscapObject.new(rule_xml: rule)
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

      def save_rule_references
        return @rule_references if @rule_references

        @rule_references = []
        new_rules.map do |rule|
          @rule_references << RuleReference.from_oscap_objects(rule.references)
        end
        RuleReference.import(@rule_references.flatten,
                             columns: %i[href label],
                             ignore: true)
      end

      def save_rules
        new_profiles = Profile.where(ref_id: profiles.keys)
        add_profiles_to_old_rules(rules_already_saved, new_profiles)
        new_rule_records = new_rules
                           .each_with_object([]).map do |oscap_rule, _new_rules|
          rule_object = Rule.new(profiles: new_profiles).from_oscap_object(oscap_rule)
          if oscap_rule.identifier
            rule_object.rule_identifier = RuleIdentifier
                                          .new(label: oscap_rule.identifier, system: oscap_rule.identifier_system)
          end
          rule_object
        end
        rule_import = Rule.import!(new_rule_records, recursive: true)
        associate_rule_references(new_rule_records)
        rule_import
      end

      def associate_rule_references(rules)
        @rule_references ||= []
        rules.zip(@rule_references).each do |rule, references|
          rule.update(rule_references: references) if references
        end
      end
    end
  end
end
