# frozen_string_literal: true

require 'prometheus_exporter/client'

RuleType = GraphQL::ObjectType.define do
  name 'Rule'
  description 'A Rule registered in Insights Compliance'

  field :id, !types.ID
  field :title, !types.String
  field :ref_id, !types.String
  field :rationale, types.String
  field :description, !types.String
  field :severity, !types.String
  field :profiles, -> { types[ProfileType] }
  field :compliant do
    type !types.Boolean
    argument :system_id, !types.String, 'Is a system compliant?'
    resolve lambda { |rule, args, _ctx|
      rule.compliant?(Host.find(args['system_id']))
    }
  end
end

ProfileType = GraphQL::ObjectType.define do
  name 'Profile'
  description 'A Profile registered in Insights Compliance'

  field :id, !types.ID
  field :name, !types.String
  field :description, types.String
  field :ref_id, !types.String
  field :compliance_threshold, !types.Float
  field :rules, -> { types[RuleType] }
  field :hosts, -> { types[SystemType] }
  field :total_host_count do
    type !types.Int
    resolve ->(obj, _args, _ctx) { obj.hosts.count }
  end
  field :compliant_host_count do
    type !types.Int
    resolve lambda { |obj, _args, _ctx|
      obj.hosts.count { |host| obj.compliant?(host) }
    }
  end
  field :compliant do
    type !types.Boolean
    argument :system_id, !types.String, 'Is a system compliant?'
    resolve lambda { |profile, args, _ctx|
      profile.compliant?(Host.find(args['system_id']))
    }
  end
  field :rules_passed do
    type !types.Int
    argument :system_id, !types.String,
             'Rules passed for a system and a profile'
    resolve lambda { |profile, args, _ctx|
      profile.results(Host.find(args['system_id'])).count { |result| result }
    }
  end
  field :rules_failed do
    type !types.Int
    argument :system_id, !types.String,
             'Rules failed for a system and a profile'
    resolve lambda { |profile, args, _ctx|
      profile.results(Host.find(args['system_id'])).count(&:!)
    }
  end

  field :last_scanned do
    type !types.String
    argument :system_id, !types.String,
             'Last time this profile was scanned for a system'
    resolve lambda { |profile, args, _ctx|
      rule_ids = profile.rules.map(&:id)
      rule_results = RuleResult.where(rule_id: rule_ids,
                                      host_id: Host.find(args['system_id']).id)
      rule_results.maximum(:updated_at) || 'Never'
    }
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
    argument :profile_id, types.String, 'Filter results by profile ID'
    resolve lambda { |obj, args, _ctx|
      obj.profiles.all? { |profile| profile.compliant?(obj) }
      profiles_compliant = if args['profile_id'].present?
                             [Profile.find(args['profile_id']).compliant?(obj)]
                           else
                             obj.profiles.map do |profile|
                               profile.compliant?(obj)
                             end.flatten
                           end

      profiles_compliant.all? true
    }
  end
  field :profile_names do
    type !types.String
    resolve ->(obj, _args, _ctx) { obj.profiles.map(&:name).join(', ') }
  end
  field :rules_passed do
    type !types.Int
    argument :profile_id, types.String, 'Filter results by profile ID'
    resolve lambda { |obj, args, _ctx|
      profile_results = if args['profile_id'].present?
                          Profile.find(args['profile_id']).results(obj)
                        else
                          obj.profiles.map do |profile|
                            profile.results(obj)
                          end.flatten
                        end
      profile_results.count { |result| result }
    }
  end
  field :rules_failed do
    type !types.Int
    argument :profile_id, types.String, 'Filter results by profile ID'
    resolve lambda { |obj, args, _ctx|
      profile_results = if args['profile_id'].present?
                          Profile.find(args['profile_id']).results(obj)
                        else
                          obj.profiles.map do |profile|
                            profile.results(obj)
                          end.flatten
                        end

      profile_results.count(&:!)
    }
  end

  field :rule_objects_failed do
    type types[RuleType]
    description 'Rules failed by a system'
    resolve lambda { |host, _args, _ctx|
      RuleResult.includes(:rule).where(
        host: host,
        result: %w[error fail notchecked]
      ).map(&:rule).uniq
    }
  end

  field :last_scanned do
    type types.String
    argument :profile_id, types.String, 'Filter results by profile ID'
    resolve lambda { |obj, args, _ctx|
      if args['profile_id'].present?
        rule_ids = Profile.find(args['profile_id']).rules.pluck(:id)
        rule_results = RuleResult.where(rule_id: rule_ids, host: obj.id)
      else
        rule_results = obj.rule_results
      end

      rule_results.maximum(:updated_at) || 'Never'
    }
  end
end

# All queries here should contain an authorization and use scopes to
# return any data
QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'The root of all queries'

  field :allSystems do
    type types[SystemType]
    description 'All systems visible by the user'
    argument :search, types.String, 'Search query'
    resolve lambda { |_obj, args, ctx|
      Pundit.policy_scope(ctx[:current_user], Host).search_for(args[:search])
    }
  end

  field :system do
    type SystemType
    argument :id, types.String
    description 'Details for a system'
    resolve lambda { |_obj, args, ctx|
      Pundit.authorize(ctx[:current_user], Host.find(args[:id]), :show?)
    }
  end

  field :allImageStreams do
    type types[SystemType]
    description 'All image streams visible by the user'
    argument :search, types.String, 'Search query'
    resolve lambda { |_obj, _args, _ctx|
      []
    }
  end

  field :allProfiles do
    type types[ProfileType]
    description 'All profiles visible by the user'
    resolve lambda { |_obj, _args, ctx|
      Pundit.policy_scope(ctx[:current_user], Profile).includes(:hosts)
    }
  end

  field :profile do
    type ProfileType
    argument :id, types.String
    resolve lambda { |_obj, args, ctx|
      Pundit.authorize(
        ctx[:current_user],
        Profile.includes(:profile_hosts, :hosts).find(args[:id]),
        :show?
      )
    }
  end
end

module ProfileMutations
  Edit = GraphQL::Relay::Mutation.define do
    name 'UpdateProfile'

    input_field :id, types.ID
    input_field :compliance_threshold, types.Float
    return_field :profile, ProfileType

    resolve lambda { |_obj, args, ctx|
      profile = Pundit.authorize(
        ctx[:current_user],
        Profile.find(args[:id]),
        :edit?
      )
      profile.update(args.to_h)
      { profile: profile }
    }
  end
end

MutationType = GraphQL::ObjectType.define do
  name 'Mutation'
  description 'The mutation root of this schema'

  field :UpdateProfile, field: ProfileMutations::Edit.field
end

Schema = GraphQL::Schema.define do
  use(GraphQL::Tracing::PrometheusTracing)
  query QueryType
  mutation MutationType
end
