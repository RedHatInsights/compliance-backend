# frozen_string_literal: true

module XCCDFReport
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      def rules_already_saved
        return @rules_already_saved if @rules_already_saved.present?

        rule_ref_ids = @oscap_parser.rule_objects.map(&:id)
        @rules_already_saved = Rule.select(:id, :ref_id)
                                   .where(ref_id: rule_ref_ids)
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
        @oscap_parser.rule_objects.reject do |rule|
          ref_ids.include? rule.id
        end
      end

      def rule_references
        references = oscap_report_references
        RuleReference.where(
          href: references.map { |r| r[:href] },
          label: references.map { |r| r[:label] }
        )
      end

      def save_rule_references
        RuleReferencesRule.import(new_rule_references, recursive: true)
      end

      def save_rules
        add_profiles_to_old_rules(rules_already_saved, new_profiles)
        Rule.import!(new_rule_records, recursive: true)
      end

      private

      def new_rule_references
        report_labels = oscap_report_references.map { |r| r[:label] }
        new_labels = report_labels - rule_references.pluck(:label)
        oscap_report_references.map do |r|
          next unless new_labels.include?(r[:label])

          RuleReferencesRule.new(
            rule_id: r[:rule_id],
            rule_reference: RuleReference.new(r.except(:rule_id))
          )
        end.compact
      end

      def oscap_report_references
        return @oscap_report_references if @oscap_report_references.present?

        rule_ref_ids = {}
        new_rule_objects = Rule.where(ref_id: new_rules.map(&:id))
        new_rule_objects.each { |rule| rule_ref_ids[rule.ref_id] = rule.id }
        @oscap_report_references = new_rules.map do |rule|
          rule.references.map { |rr| rr.merge(rule_id: rule_ref_ids[rule.id]) }
        end.flatten
      end

      def new_profiles
        @new_profiles ||= Profile.where(ref_id: @oscap_parser.profiles.keys,
                                        account_id: @account.id)
      end

      def new_rule_records
        @new_rule_records ||= new_rules.each_with_object([])
                                       .map do |oscap_rule, _new_rules|
          rule_object = Rule.new(profiles: new_profiles)
                            .from_oscap_object(oscap_rule)
          rule_object.rule_identifier = RuleIdentifier
                                        .from_oscap_rule(oscap_rule)
          rule_object
        end
      end
    end
  end
end
