# frozen_string_literal: true

module Types
  # Definition of the Profile type in GraphQL
  class Profile < Types::BaseObject
    graphql_name 'Profile'
    description 'A Profile registered in Insights Compliance'

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :ref_id, String, null: false
    field :compliance_threshold, Float, null: false
    field :benchmark_id, ID, null: false
    field :account_id, ID, null: false
    field :rules, [::Types::Rule], null: true, extras: [:lookahead] do
      argument :system_id, String,
               'System ID to filter by', required: false
      argument :identifier, String,
               'Rule identifier to filter by', required: false
      argument :references, [String],
               'Rule references to filter by', required: false
    end

    # rubocop:disable AbcSize
    def rules(args = {})
      selected_columns = (args[:lookahead].selections.map(&:name) &
                         ::Rule.column_names.map(&:to_sym)) << :id

      rules = rules_for_system(args, selected_columns) if system_id(args)
      rules = object.rules.select(selected_columns) if rules.blank?
      rules = rules.with_identifier(args[:identifier]) if args.dig(:identifier)
      rules = rules.with_references(args[:references]) if args.dig(:references)
      rules = lookahead_includes(args[:lookahead], rules,
                                 identifier: :rule_identifier)
      parent_profile(rules)
      rules
    end
    # rubocop:enable AbcSize

    field :hosts, [::Types::System], null: true
    field :business_objective, ::Types::BusinessObjective, null: true
    field :business_objective_id, ID, null: true
    field :total_host_count, Int, null: false

    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant?', required: false
    end

    field :rules_passed, Int, null: false do
      argument :system_id, String,
               'Rules passed for a system and a profile', required: false
    end

    field :rules_failed, Int, null: false do
      argument :system_id, String,
               'Rules failed for a system and a profile', required: false
    end

    field :last_scanned, String, null: false do
      argument :system_id, String,
               'Last time this profile was scanned for a system',
               required: false
    end

    field :compliant_host_count, Int, null: false

    def compliant_host_count
      object.hosts.count { |host| object.compliant?(host) }
    end

    def total_host_count
      object.hosts.count
    end

    def compliant(args = {})
      host_results = latest_test_result(args)&.rule_results
      host_results.present? &&
        (
          host_results.where(result: 'pass').count /
          host_results.count.to_f
        ) >=
          (object.compliance_threshold / 100.0)
    end

    def rules_passed(args = {})
      return 0 if (@latest_test_result = latest_test_result(args)).blank?

      @latest_test_result.rule_results.passed.count
    end

    def rules_failed(args = {})
      return 0 if (@latest_test_result = latest_test_result(args)).blank?

      @latest_test_result.rule_results.failed.count
    end

    def last_scanned(args = {})
      latest_test_result(args)&.end_time&.iso8601 || 'Never'
    end

    private

    def system_id(args)
      args[:system_id] || context[:parent_system_id]
    end

    def parent_profile(rules)
      context[:parent_profile_id] ||= {}
      rules.each { |rule| context[:parent_profile_id][rule.id] = object.id }
    end

    def latest_test_result(args)
      TestResult.latest(object.id, system_id(args))
    end

    def rules_for_system(args, selected_columns)
      host = Host.find(system_id(args)) if system_id(args).present?
      object.rules_for_system(host, selected_columns) if host.present?
    end
  end
end
