# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module ProfileRules
    extend ActiveSupport::Concern

    included do
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def save_profile_rules
        ::ProfileRule.transaction do
          ::ProfileRule.import!(
            profile_rules.select(&:new_record?), ignore: true
          )

          base = ::ProfileRule.joins(profile: :benchmark)
                              .where('profiles.parent_profile_id' => nil)

          # links_to_remove(base).delete_all

          # FIXME: dry-run on the destructive operation first
          links_to_remove(base).joins(:rule).select(
            'profiles.ref_id AS profile_ref_id', 'rules.ref_id AS rule_ref_id',
            'benchmarks.ref_id AS benchmark_ref_id', 'benchmarks.version AS ver'
          ).each do |link|
            Rails.logger.info(%(
              "Removing link between profile
              #{link.attributes['profile_ref_id']}
              and rule
              #{link.attributes['rule_ref_id']}
              under benchmark
              #{link.attributes['benchmark_ref_id']}
              version
              #{link.attributes['ver']}
              "
            ).gsub(/\n|\s+/, ' '))
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      private

      def profile_rules
        @profile_rules ||= @op_profiles.flat_map do |op_profile|
          profile_id = profile_id_for(ref_id: op_profile.id)
          rule_ids_for(ref_ids: op_profile.selected_rule_ids).map do |rule_id|
            ::ProfileRule.find_or_initialize_by(
              profile_id: profile_id, rule_id: rule_id
            )
          end
        end
      end

      def links_to_remove(base)
        grouped_rules = profile_rules.group_by(&:profile_id)
        grouped_rules.reduce(ProfileRule.none) do |query, (profile_id, prs)|
          query.or(
            base.where(profile_id: profile_id)
                .where.not(rule_id: prs.map(&:rule_id))
          )
        end
      end

      def profile_id_for(ref_id:)
        @profiles.find { |p| p.ref_id == ref_id }.id
      end

      def rule_ids_for(ref_ids:)
        @rules.select { |r| ref_ids.include?(r.ref_id) }.map(&:id)
      end
    end
  end
end
