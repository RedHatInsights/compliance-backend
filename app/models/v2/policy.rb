# frozen_string_literal: true

module V2
  # Model for SCAP policies
  class Policy < ApplicationRecord
    include V2::RuleTree

    # FIXME: clean up after the remodel
    self.table_name = :v2_policies
    self.primary_key = :id

    belongs_to :account, class_name: 'Account'
    belongs_to :profile, class_name: 'V2::Profile'
    belongs_to :report, class_name: 'V2::Report', foreign_key: :id, optional: true # rubocop:disable Rails/InverseOf

    has_one :security_guide, through: :profile, class_name: 'V2::SecurityGuide'

    has_many :tailorings, class_name: 'V2::Tailoring', dependent: :destroy
    has_many :tailoring_rules, through: :tailorings, class_name: 'V2::TailoringRule', dependent: :destroy
    has_many :rules, through: :tailoring_rules, class_name: 'V2::Rule'
    has_many :policy_systems, class_name: 'V2::PolicySystem', dependent: :destroy
    has_many :systems, through: :policy_systems, class_name: 'V2::System'
    has_many :rule_groups, through: :security_guide, class_name: 'V2::RuleGroup'

    validates :account, presence: true
    validates :profile, presence: true
    validates :title, presence: true
    validates :compliance_threshold, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }

    sortable_by :title
    sortable_by :os_major_version, 'security_guide.os_major_version'
    sortable_by :total_system_count
    sortable_by :business_objective
    sortable_by :compliance_threshold

    searchable_by :title, %i[like unlike eq ne]

    searchable_by :os_major_version, %i[eq ne in notin], except_parents: %i[systems] do |key, op, val|
      values = val.split(',').map(&:to_i)

      { conditions: arel_inotineqneq(op, V2::SecurityGuide.arel_table.alias('security_guide')[key], values).to_sql }
    end

    searchable_by :os_minor_version, %i[eq] do |_key, _op, val|
      # Rails doesn't support composed foreign keys yet, so we have to manually join with `SupportedProfile` using
      # `Profile#ref_id` and `SecurityGuide#os_major_version`.
      supported_profiles = arel_join_fragment(
        arel_table.join(V2::SupportedProfile.arel_table).on(
          V2::SupportedProfile.arel_table[:ref_id].eq(V2::Profile.arel_table.alias(:profile)[:ref_id]).and(
            V2::SupportedProfile.arel_table[:os_major_version].eq(
              V2::SecurityGuide.arel_table.alias(:security_guide)[:os_major_version]
            )
          )
        )
      )

      match_os_minors = AN::NamedFunction.new('ANY', [V2::SupportedProfile.arel_table[:os_minor_versions]])
      ids = V2::Policy.unscoped
                      .joins(profile: :security_guide).joins(supported_profiles)
                      .where(Arel::Nodes.build_quoted(val).eq(match_os_minors))
                      .select(arel_table[:id])

      { conditions: AN::In.new(arel_table[:id], ids.arel).to_sql }
    end

    before_validation :ensure_default_values

    def delete_associated
      report.delete_associated
      V2::Tailoring.where(policy_id: id).delete_all
      V2::PolicySystem.where(policy_id: id).delete_all
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

    def os_minor_versions
      V2::SupportedProfile.find_by!(ref_id: ref_id, os_major_version: os_major_version).os_minor_versions
    end

    # This method is calling an APIv1 model to update the cached counter in APIv1+GQL for maintaining
    # compatibility. After we stop using these old APIs, this will be obsolete and should be deleted.
    def __v1_update_total_system_count
      ::Policy.find(id).update_counters!
    end

    private

    def ensure_default_values
      self.title ||= profile&.title
      self.description ||= profile&.description
      self.compliance_threshold ||= 100.0
    end
  end
end
