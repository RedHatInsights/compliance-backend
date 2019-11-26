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
      host = Host.find(args[:system_id]) if args[:system_id].present?
      rules = object.rules_for_system(host, selected_columns) if host.present?
      rules = object.rules.select(selected_columns) if host.blank?
      rules = rules.with_identifier(args[:identifier]) if args.dig(:identifier)
      rules = rules.with_references(args[:references]) if args.dig(:references)
      rules = lookahead_includes(args[:lookahead], rules,
                                 identifier: :rule_identifier)
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
      CollectionLoader.for(object.class, :hosts).load(object).then do |hosts|
        hosts.count { |host| object.compliant?(host) }
      end
    end

    def total_host_count
      CollectionLoader.for(object.class, :hosts).load(object).then do |hosts|
        hosts.count
      end
    end

    def compliant(args = {})
      RecordLoader.for(Host).load(system_id(args)).then do |host|
        object.compliant?(host)
      end
    end

    def rules_passed(args = {})
      RecordLoader.for(Host).load(system_id(args)).then do |host|
        host.rules_passed(object)
      end
    end

    def rules_failed(args = {})
      RecordLoader.for(Host).load(system_id(args)).then do |host|
        host.rules_failed(object)
      end
    end

    def last_scanned(args = {})
      CollectionLoader.for(object.class, :rules).load(object).then do |rules|
        rule_results = RuleResult.where(
          rule_id: rules.pluck(:id),
          host_id: system_id(args)
        )
        rule_results.maximum(:end_time)&.iso8601 || 'Never'
      end
    end

    private

    def system_id(args)
      args[:system_id] || context[:parent_system_id]
    end
  end
end
