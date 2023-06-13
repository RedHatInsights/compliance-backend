# frozen_string_literal: true

# Service for removing orphaned links
class OrphanedLinksRemover
  class << self
    # rubocop:disable Metrics/AbcSize
    def run!
      return unless Host.table_exists?

      ProfileRule.left_outer_joins(:profile).left_outer_joins(:rule).where.missing(:profile).or(
        ProfileRule.where(rules: { id: nil })
      ).destroy_all

      RuleResult.left_outer_joins(:rule).left_outer_joins(:host).where.missing(:rule).or(
        RuleResult.where('inventory.hosts': { id: nil })
      ).destroy_all

      TestResult.left_outer_joins(:profile).left_outer_joins(:host).where.missing(:profile).or(
        RuleResult.where('inventory.hosts': { id: nil })
      ).destroy_all
    end
    # rubocop:enable Metrics/AbcSize
  end
end
