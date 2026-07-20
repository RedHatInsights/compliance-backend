# frozen_string_literal: true

# Model for SCAP policies
class Policy < ApplicationRecord
  include RuleTree

  # FIXME: clean up after the remodel
  self.table_name = :policies_v2
  self.primary_key = :id

  belongs_to :account, class_name: 'Account'
  belongs_to :profile, class_name: 'Profile'
  belongs_to :report, class_name: 'Report', foreign_key: :id, optional: true # rubocop:disable Rails/InverseOf

  has_one :security_guide, through: :profile, class_name: 'SecurityGuide'

  TOTAL_SYSTEM_COUNT = lambda do
    AN::NamedFunction.new('COUNT', [PolicySystem.arel_table[:id]])
  end

  has_many :tailorings, class_name: 'Tailoring', dependent: :destroy
  has_many :tailoring_rules, through: :tailorings, class_name: 'TailoringRule', dependent: :destroy
  has_many :rules, through: :tailoring_rules, class_name: 'Rule'
  has_many :policy_systems, class_name: 'PolicySystem', dependent: :destroy
  has_many :systems, through: :policy_systems, class_name: 'System'
  has_many :rule_groups, through: :security_guide, class_name: 'RuleGroup'

  validates :account, presence: true
  validates :profile, presence: true
  validates :title, presence: true, uniqueness: { scope: :account_id }
  validates :compliance_threshold, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 100
  }

  sortable_by :title
  sortable_by :os_major_version, 'security_guide.os_major_version'
  sortable_by :total_system_count, 'aggregate_total_system_count'
  sortable_by :business_objective
  sortable_by :compliance_threshold

  searchable_by :title, %i[like unlike eq ne]
  searchable_by :os_major_version, %i[eq ne in notin], except_parents: %i[systems] do |_key, op, val|
    bind = ['IN', 'NOT IN'].include?(op) ? '(?)' : '?'

    {
      conditions: "security_guide.os_major_version #{op} #{bind}",
      parameter: [val.split(',').map(&:to_i)]
    }
  end
  searchable_by :os_minor_version, %i[eq] do |_key, _op, val|
    # Rails doesn't support composed foreign keys yet, so we have to manually join with `SupportedProfile` using
    # `Profile#ref_id` and `SecurityGuide#os_major_version`.
    supported_profiles = arel_join_fragment(
      arel_table.join(SupportedProfile.arel_table).on(
        SupportedProfile.arel_table[:ref_id].eq(Profile.arel_table.alias(:profile)[:ref_id]).and(
          SupportedProfile.arel_table[:os_major_version].eq(
            SecurityGuide.arel_table.alias(:security_guide)[:os_major_version]
          )
        )
      )
    )

    match_os_minors = Arel::Nodes::NamedFunction.new('ANY', [SupportedProfile.arel_table[:os_minor_versions]])
    ids = Policy.unscoped
                .joins(profile: :security_guide).joins(supported_profiles)
                .where(Arel::Nodes.build_quoted(val).eq(match_os_minors))
                .select(arel_table[:id])

    { conditions: "policies_v2.id IN (#{ids.to_sql})" }
  end

  before_validation :ensure_default_values

  def delete_associated
    report.delete_associated
    Tailoring.where(policy_id: id).delete_all
    PolicySystem.where(policy_id: id).delete_all
  end

  def os_major_version
    attributes['security_guide__os_major_version'] || try(:security_guide)&.os_major_version
  end

  def profile_title
    attributes['profile__title'] || try(:profile)&.title
  end

  def ref_id
    attributes['profile__ref_id'] || try(:profile)&.ref_id
  end

  # Fallback for when the object is rendered without the SQL aggregate (e.g. after create).
  def total_system_count
    attributes['aggregate_total_system_count'] || policy_systems.count
  end
  alias aggregate_total_system_count total_system_count

  def os_minor_versions
    SupportedProfile.find_by!(ref_id: ref_id, os_major_version: os_major_version).os_minor_versions
  end

  private

  def ensure_default_values
    self.description ||= profile&.description
    self.compliance_threshold ||= 100.0
  end
end
