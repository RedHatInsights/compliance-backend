# frozen_string_literal: true

# Service for dowloading SSG remediation playbooks
class PlaybookDownloader
  class << self
    def playbooks_exist?(rules)
      rules.inject({}) do |obj, rule|
        obj.merge(rule.id => playbook_exists?(rule))
      end
    end

    def playbook_exists?(rule)
      playbook_list(rule.benchmark.os_major_version).include?(rule.short_ref_id)
    end

    private

    def playbook_list(os_major_version)
      @cache ||= {}
      @cache[os_major_version] ||= begin
        file = SafeDownloader.download(playbook_list_url(os_major_version))
        JSON.parse(file.read).map do |row|
          row['name'].sub(/\.yml$/, '')
        end
      end
    end

    def playbook_list_url(os_major_version)
      [
        Settings.compliance_ssg_url,
        'playbooks',
        "rhel#{os_major_version}",
        'all'
      ].join('/')
    end
  end
end
