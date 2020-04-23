# frozen_string_literal: true

# Class to deal with preloading various attributes for rules, such as
# rule results, compliant,and references
module RulesPreload
  include GraphQL::Schema::Interface

  def rules(args = {})
    context[:parent_profile_id] ||= {}
    return all_rules if system_id(args).blank?

    latest_test_result_batch(args).then do |latest_test_result|
      latest_rule_results_batch(latest_test_result).then do |rule_results|
        rules_for_rule_results_batch(rule_results).then do |rules|
          initialize_rules_context(rules, rule_results, args)
          rules
        end
      end
    end
  end

  def latest_rule_results_batch(latest_test_result)
    if latest_test_result.blank?
      return Promise.resolve(::RuleResult.where('1=0'))
    end

    ::CollectionLoader.for(::TestResult, :rule_results).load(latest_test_result)
  end

  def rules_for_rule_results_batch(rule_results)
    ::RecordLoader.for(::Rule).load_many(rule_results.pluck(:rule_id))
  end

  def all_rules
    ::CollectionLoader.for(::Profile, :rules).load(object).then do |rules|
      rules
    end
  end

  def initialize_rules_context(rules, rule_results, args = {})
    rules.each do |rule|
      context[:parent_profile_id][rule.id] = object.id
    end
    if args[:lookahead].selects?(:references)
      initialize_rule_references_context(rule_results)
    end
    return unless args[:lookahead].selects?(:compliant)

    context[:rule_results] ||= {}
    initialize_rule_results_context(rule_results)
  end

  def initialize_rule_references_context(rule_results)
    grouped_rules_references = ::RuleReferencesRule.select(
      :rule_id, :rule_reference_id
    ).distinct.where(
      rule_id: rule_results.select(:rule_id)
    ).group_by(&:rule_id)
    grouped_rules_references.each do |rule_id, references|
      context[:"rule_references_#{rule_id}"] =
        references.pluck(:rule_reference_id)
    end
  end

  def initialize_rule_results_context(rule_results)
    rule_results.each do |rule_result|
      context[:rule_results][rule_result.rule_id] ||= {}
      context[:rule_results][rule_result.rule_id][object.id] =
        rule_result.result
    end
  end
end
