# frozen_string_literal: true

# Service for dowloading SSG configuration files
class SsgConfigDownloader
  DS_FILE_PATH = 'config/supported_ssg.yaml'
  DS_FALLBACK_PATH = 'config/supported_ssg.default.yaml'
  AT_FILE_PATH = 'config/ssg-ansible-tasks.yaml'
  AT_FALLBACK_PATH = 'config/ssg-ansible-tasks.default.yaml'

  class << self
    def ssg_ds
      File.read(ssg_ds_file)
    end

    def ssg_ansible_tasks
      File.read(ssg_ansible_tasks_file)
    end

    def ssg_ds_checksum
      Digest::MD5.file(ssg_ds_file).hexdigest
    end

    def ssg_ansible_tasks_checksum
      Digest::MD5.file(ssg_ansible_tasks_file).hexdigest
    end

    def update_ssg_ds
      ssg_content = download(ssg_datastream_config_url)&.read
      ssg_content && File.open(DS_FILE_PATH, 'w') do |f|
        f.write(ssg_content)
      end
    end

    def update_ssg_ansible_tasks
      ssg_content = download(ssg_ansible_tasks_config_url)&.read
      ssg_content && File.open(AT_FILE_PATH, 'w') do |f|
        f.write(ssg_content)
      end
    end

    def ssg_datastream_config_url
      [
        Settings.compliance_ssg_url,
        Settings.supported_ssg_ds_config
      ].join('/')
    end

    def ssg_ansible_tasks_config_url
      [
        Settings.compliance_ssg_url,
        Settings.supported_ssg_ansible_tasks_config
      ].join('/')
    end

    private

    def ssg_ds_file
      File.new(File.exist?(DS_FILE_PATH) ? DS_FILE_PATH : DS_FALLBACK_PATH)
    end

    def ssg_ansible_tasks_file
      File.new(File.exist?(AT_FILE_PATH) ? AT_FILE_PATH : AT_FALLBACK_PATH)
    end

    def download(url)
      file = SafeDownloader.download(url)
      Rails.logger.audit_success("Downloaded config from #{url}")
      file
    rescue StandardError => e
      Rails.logger.audit_fail("Failed to download config from #{url}: #{e}")
      nil
    end
  end
end
