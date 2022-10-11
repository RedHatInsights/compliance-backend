# frozen_string_literal: true

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  OS_MINOR_VERSION = Arel.sql("system_profile->'operating_system'->'minor'")
  OS_MAJOR_VERSION = Arel.sql("system_profile->'operating_system'->'major'")
  OS_VERSION = Arel.sql("system_profile->'operating_system'")
  TAGS = Arel.sql('jsonb_array_elements(tags)')

  sortable_by :name, :display_name
  sortable_by :os_major_version, OS_MAJOR_VERSION
  sortable_by :os_minor_version, OS_MINOR_VERSION
  sortable_by(
    :ssg_version,
    Arel.sql("string_to_array(benchmarks.version, '.')::int[]"),
    scope: :with_benchmark
  )

  self.table_name = 'inventory.hosts'
  self.primary_key = 'id'

  include HostSearching

  has_many :rule_results, dependent: :delete_all
  has_many :rules, through: :rule_results, source: :rule
  has_many :policy_hosts, dependent: :destroy
  has_many :test_results, dependent: :destroy
  include SystemLike

  has_many :test_result_profiles, -> { distinct },
           through: :test_results, source: :profile
  has_many :policies, through: :policy_hosts
  has_many :assigned_profiles, through: :policies, source: :profiles
  has_many :assigned_internal_profiles, -> { external(false) },
           through: :policies, source: :profiles

  scope :with_benchmark, lambda { |profile = nil|
    profile ||= RequestStore.store['scoped_search_context_profiles']

    left_outer_joins(test_result_profiles: :benchmark).where(
      profiles: { id: profile.pluck(:id) }
    )
  }

  def self.os_minor_versions(hosts)
    distinct.where(id: hosts).pluck(OS_MINOR_VERSION)
  end

  def self.available_os_versions
    distinct.pluck(OS_VERSION)
  end

  def readonly?
    true
  end

  def self.taggable?
    true
  end

  def self.os_version_query(path, values, equal = true)
    query = equal ? :in : :not_in

    raise ArgumentError unless %i[major minor].include?(path)

    Arel::Nodes::InfixOperation.new(
      '->',
      arel_table[:system_profile],
      Arel::Nodes::SqlLiteral.new("'operating_system'->'#{path}'")
    ).send(query, values)
  end

  alias destroy save
  alias delete save

  def policy_hosts?
    policy_hosts.any?
  end
  alias has_policy policy_hosts?

  def os_major_version
    system_profile&.dig('operating_system', 'major')
  end

  def os_minor_version
    system_profile&.dig('operating_system', 'minor')
  end

  def name
    display_name
  end

  def all_profiles
    Profile.where(id: assigned_profiles)
           .or(Profile.where(id: test_result_profiles))
           .distinct
  end
end
