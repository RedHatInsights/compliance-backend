# frozen_string_literal: true

# Deletes a system and cleans up its associated data
class SystemDeleteJob < ApplicationJob
  queue_as :deletes

  include InventorySystemConcurrency

  def perform(message)
    @message = message
    @id = @message.dig('id')
    @org_id = @message.dig('org_id')

    cleanup_system_relations if soft_delete_system
  end

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def soft_delete_system
    computed_timestamp = delete_timestamp
    # rubocop:disable Rails/SkipsModelValidations
    result = System.unscoped
                   .where(id: @id)
                   .where('updated IS NULL OR updated < ?', computed_timestamp)
                   .update_all(deleted_at: computed_timestamp)
    # rubocop:enable Rails/SkipsModelValidations

    if result.zero?
      Rails.logger.info("[SystemDeleteJob] Ignored stale delete event or no active system found for ID #{@id}")
      Yabeda.compliance_system_delete_noop_total.increment({})
      false
    else
      Rails.logger.audit_success("[SystemDeleteJob] Soft-deleted system #{@id}")
      true
    end
  rescue StandardError => e
    Rails.logger.audit_fail("[SystemDeleteJob] Failed to soft-delete system #{@id}: #{e.message}")
    raise e
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def delete_timestamp
    timestamp_str = @message.dig('updated') || @message.dig('timestamp')
    begin
      parsed_time = Time.zone.parse(timestamp_str) if timestamp_str
      if timestamp_str && parsed_time.nil?
        Rails.logger.warn("[SystemDeleteJob] Failed to parse timestamp '#{timestamp_str}' " \
                          "for system #{@id}, falling back to current time")
      end
      parsed_time || Time.current
    rescue StandardError => e
      Rails.logger.warn("[SystemDeleteJob] Error parsing timestamp '#{timestamp_str}' " \
                        "for system #{@id}: #{e.message}")
      Time.current
    end
  end
  # rubocop:enable Metrics/MethodLength

  def cleanup_system_relations
    num_removed = remove_related
    audit_success if num_removed.positive?
  rescue StandardError => e
    audit_fail(e)
    raise
  end

  def remove_related
    ActiveRecord::Base.transaction do
      [
        remove_related_rule_results,
        remove_related_test_results,
        remove_related_policy_systems
      ].sum
    end
  end

  def remove_related_rule_results
    RuleResult.where(test_result_id: historical_test_results.select(:id)).delete_all
  end

  def remove_related_test_results
    historical_test_results.delete_all
  end

  def remove_related_policy_systems
    PolicySystem.where(system_id: @id).delete_all
  end

  def historical_test_results
    HistoricalTestResult.where(system_id: @id)
  end

  def audit_fail(error)
    Rails.logger.audit_fail("[#{@org_id}] Failed to delete related records for System #{@id}: #{error.message}")
  end

  def audit_success
    Rails.logger.audit_success("[#{@org_id}] Deleted related records for System #{@id}")
  end
end
