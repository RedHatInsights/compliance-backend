# frozen_string_literal: true

# Service for dowloading SSG remediation playbooks
class PlaybookDownloader
  class << self
    def playbook_exists?(rule, profile = nil)
      download(playbook_url(rule, profile&.short_ref_id)).present?
    end

    def playbooks_exist?(rules)
      rules.map do |rule|
        [rule.id, playbook_exists?(rule)]
      end.to_h
    end

    private

    def playbook_url(rule, profile_short_ref_id = nil)
      [
        Settings.compliance_ssg_url,
        'playbooks',
        "rhel#{rule.benchmark.os_major_version}",
        profile_short_ref_id || 'all',
        "#{rule.short_ref_id}.yml"
      ].join('/')
    end

    def download(url)
      file = SafeDownloader.download(url)
      Rails.logger.audit_success("Downloaded playbook from #{url}")
      file
    rescue StandardError => e
      Rails.logger.audit_fail("Failed to download playbook from #{url}: #{e}")
      nil
    end
  end
end
