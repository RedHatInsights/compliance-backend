# frozen_string_literal: true

# Migrates ref IDs from reports to comply with the expected standard.
# Profile ref IDs should look like "xccdf_org.ssgproject.content_profile_*"
# Rule ref IDs should look like "xccdf_org.ssgproject.content_rule_*"
#
# Disabling ClassLength here as the migration is likely going to be removed
# at some point since we don't accept these reports anymore and old data was
# already migrated
# rubocop:disable Metrics/ClassLength
class XCCDFReportMigration
  def initialize(account, noop)
    @account = account
    @noop = noop
    @logger = Sidekiq.logger
  end

  # rubocop:disable Metrics/MethodLength
  def run
    xccdf_profiles = broken_profiles
    @logger.info "Found #{xccdf_profiles.count} profiles from XCCDF reports."\
      ' Renaming profiles...'
    rename_profiles(xccdf_profiles)
    @logger.info "Profiles rename finished \n-------------------------------\n"\
      'Some profiles might have not been renamed if the name '\
      'conflicts with another profile in the same account.'\
      "Let's proceed to migrating the XCCDF profile results into the"\
      ' DS profile results'
    xccdf_profiles = broken_profiles
    @logger.info "Found #{xccdf_profiles.count} profiles from XCCDF reports."
    migrate_profiles(xccdf_profiles)
  end
  # rubocop:enable Metrics/MethodLength

  def broken_profiles
    Profile.where(account_id: @account.id).where.not(
      'ref_id LIKE ?', 'xccdf_org.ssgproject.content_profile_%'
    )
  end

  def rename_profiles(xccdf_profiles)
    return if @noop

    xccdf_profiles.map do |profile|
      profile.update(
        ref_id: "xccdf_org.ssgproject.content_profile_#{profile.ref_id}"
      )
      migrate_rules(profile.rules, profile) if profile.errors.empty?
    end
  end

  def find_matching_profile(xccdf_profile)
    Profile.where(
      account_id: @account.id,
      ref_id: "xccdf_org.ssgproject.content_profile_#{xccdf_profile.ref_id}"
    ).first
  end

  def migrate_profile_hosts(xccdf_profile, ds_profile)
    return if @noop

    @logger.info(ProfileHost
      .where(profile_id: xccdf_profile.id)
      .map { |profile_host| profile_host.update(profile_id: ds_profile.id) })
    @logger.info 'Host migration finished'
  end

  def migrate_rule(xccdf_rule, ds_rule)
    # Justification: Enhance the speed of the mass-migration
    # rubocop:disable Rails/SkipsModelValidations
    rule_result = RuleResult.where(rule_id: xccdf_rule.id)
                            .update_all(rule_id: ds_rule.id)
    # rubocop:enable Rails/SkipsModelValidations
    @logger.info " - #{rule_result}"
    @logger.info ' - Rule migration done'
  end

  def rename_rule(xccdf_rule, ds_rule)
    return ds_rule if ds_rule.present?

    @logger.info ' - Matching DS rule NOT found. Renaming..'
    xccdf_rule.update(
      ref_id: "xccdf_org.ssgproject.content_rule_#{xccdf_rule.ref_id}"
    )
    xccdf_rule.reload
  end

  def migrate_rules(rules, ds_profile)
    rules.each do |xccdf_rule|
      @logger.info " - Migrating rule #{xccdf_rule.ref_id}"
      ds_rule = ds_profile.rules.find_by(
        ref_id: "xccdf_org.ssgproject.content_rule_#{xccdf_rule.ref_id}"
      )
      ds_rule = rename_rule(xccdf_rule, ds_rule)
      next if @noop

      ds_profile.rules << ds_rule unless ds_profile.rules.include? ds_rule
      migrate_rule(xccdf_rule, ds_rule)
    end
  end

  def destroy_profile(xccdf_profile)
    xccdf_profile.rules.map(&:destroy)
    xccdf_profile.destroy
  end

  # rubocop:disable Metrics/AbcSize
  def migrate_profile(xccdf_profile)
    ds_profile = find_matching_profile(xccdf_profile)
    @logger.info "Found matching DS profile #{ds_profile.ref_id} in "\
      "account #{ds_profile.account.id}"
    @logger.info "Migrating hosts from profile #{xccdf_profile.ref_id} to "\
      " #{ds_profile.ref_id}"
    migrate_profile_hosts(xccdf_profile, ds_profile)
    @logger.info "Migrating rules from profile #{xccdf_profile.ref_id} to "\
      " #{ds_profile.ref_id}"
    migrate_rules(xccdf_profile.rules, ds_profile)
    migrate_test_results(xccdf_profile.test_results, ds_profile)
  end
  # rubocop:enable Metrics/AbcSize

  def migrate_test_results(test_results, ds_profile)
    # rubocop:disable Rails/SkipsModelValidations
    test_results.update_all(profile_id: ds_profile.id)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def migrate_profiles(xccdf_profiles)
    xccdf_profiles.each do |xccdf_profile|
      ActiveRecord::Base.transaction do
        @logger.info "Migrating: XCCDF profile #{xccdf_profile.ref_id} in "\
          "account #{xccdf_profile.account.id}"
        migrate_profile(xccdf_profile)
        next if @noop

        destroy_profile(xccdf_profile)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
