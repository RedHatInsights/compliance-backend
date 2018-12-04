ProfileType = GraphQL::ObjectType.define do
  name 'Profile'
  description 'A Profile registered in Insights Compliance'

  field :id, !types.ID
  field :name, !types.String
  field :description, types.String
  field :ref_id, !types.String
  field :total_host_count do
    type !types.Int
    resolve -> (obj, args, ctx) { obj.hosts.count }
  end
  field :compliant_host_count do
    type !types.Int
    resolve -> (obj, args, ctx) { obj.hosts.count { |host| obj.compliant?(host) } }
  end
end

SystemType = GraphQL::ObjectType.define do
  name 'System'
  description 'A System registered in Insights Compliance'

  field :id, !types.ID
  field :name, !types.String
  field :profiles, -> { types[ProfileType] }
  field :compliant do
    type !types.Boolean
    resolve -> (obj, args, ctx) {
      obj.profiles.all? { |profile| profile.compliant?(obj) }
    }
  end
  field :profile_names do
    type !types.String
    resolve -> (obj, args, ctx) { obj.profiles.map(&:name).join(', ') }
  end
  field :rules_passed do
    type !types.Int
    argument :profile_id, types.String, 'Filter results by profile ID'
    resolve -> (obj, args, ctx) {
      if args['profile_id'].present?
        profile_results = Profile.find(args['profile_id']).results(obj)
      else
        profile_results = obj.profiles.map { |profile| profile.results(obj) }.flatten
      end
      profile_results.count { |result| result }
    }
  end
  field :rules_failed do
    type !types.Int
    argument :profile_id, types.String, 'Filter results by profile ID'
    resolve -> (obj, args, ctx) {
      if args['profile_id'].present?
        profile_results = Profile.find(args['profile_id']).results(obj)
      else
        profile_results = obj.profiles.map { |profile| profile.results(obj) }.flatten
      end

      profile_results.count { |result| !result }
    }
  end
  field :last_scanned do
    type types.String
    argument :profile_id, types.String, 'Filter results by profile ID'
    resolve -> (obj, args, ctx) {
      if args['profile_id'].present?
        rule_ids = Profile.find(args['profile_id']).rules.map(&:id)
        rule_results = RuleResult.where(rule_id: rule_ids, host: obj.id)
      else
        rule_results = obj.rule_results
      end

      rule_results.maximum(:updated_at) || 'Never'
    }
  end
end

QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'The root of all queries'

  field :allSystems do
    type types[SystemType]
    description 'All systems visible by the user'
    resolve -> (obj, args, ctx) { Host.all }
  end

  field :allProfiles do
    type types[ProfileType]
    description 'All profiles visible by the user'
    resolve -> (obj, args, ctx) { Profile.all }
  end

  field :profile do
    type ProfileType
    argument :id, types.String
    resolve -> (obj, args, ctx) { Profile.find(args[:id]) }
  end
end

Schema = GraphQL::Schema.define do
  query QueryType
end
