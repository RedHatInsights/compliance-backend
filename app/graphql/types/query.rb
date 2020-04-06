# frozen_string_literal: true

module Types
  # This type contains all of the possible GraphQL queries
  class Query < Types::BaseObject
    include Fields

    graphql_name 'Query'
    description 'The root of all queries'

    collection_field :systems, Types::System
    collection_field :profiles, Types::Profile
    collection_field :test_results, Types::TestResult
    record_field :profile, Types::Profile
    record_field :test_result, Types::TestResult

    field :all_systems, [Types::System], null: true do
      description 'All systems visible by the user'
      argument :search, String, 'Search query', required: false
      argument :per_page, Int, 'Page', required: false
      argument :page, Int, 'Per page', required: false
      argument :profile_id, String, 'Profile Id', required: false
    end

    field :system, Types::System, null: true do
      description 'Details for a system'
      argument :id, String, required: true
    end

    field :all_image_streams, [Types::System], null: true do
      description 'All image streams visible by the user'
      argument :search, String, 'Search query', required: false
    end

    field :all_profiles, [Types::Profile], null: true do
      description 'All profiles visible by the user'
    end

    field :all_benchmarks, [Types::Benchmark], null: true do
      description 'All benchmarks visible by the user'
    end

    field :latest_benchmarks, [Types::Benchmark], null: true do
      description 'Latest benchmarks visible by the user'
    end

    field :benchmark, Types::Benchmark, null: true do
      argument :id, String, required: true
    end

    field :profile, Types::Profile, null: true do
      argument :id, String, required: true
    end

    field :business_objectives, [Types::BusinessObjective], null: true do
      description 'All business objectives visible by the user'
    end

    def all_systems(args = {})
      Pundit.policy_scope(context[:current_user], ::Host)
            .search_for(args[:search])
            .paginate(page: args[:page], per_page: args[:per_page])
    end

    def system(id:)
      Pundit.authorize(context[:current_user], ::Host.find(id), :show?)
    end

    def all_image_streams
      []
    end

    def all_profiles
      Pundit.policy_scope(context[:current_user], ::Profile).includes(:hosts)
    end

    def profile(id:)
      Pundit.authorize(
        context[:current_user],
        ::Profile.includes(:profile_hosts, :hosts).find(id),
        :show?
      )
    end

    def business_objectives
      Pundit.policy_scope(context[:current_user], ::BusinessObjective)
    end

    def all_benchmarks
      Pundit.policy_scope(context[:current_user], ::Xccdf::Benchmark)
    end

    def latest_benchmarks
      Pundit.authorize(
        context[:current_user],
        ::Xccdf::Benchmark.latest,
        :index?, policy_class: BenchmarkPolicy
      )
    end

    def benchmark(id:)
      Pundit.authorize(
        context[:current_user],
        ::Xccdf::Benchmark.find(id),
        :show?
      )
    end
  end
end
