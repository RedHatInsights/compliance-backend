# frozen_string_literal: true

# Service for dowloading SSG configuration files
class SsgConfigDownloader
  class << self
    SSG_DS_FILE = File.new('config/supported_ssg.yaml')

    def ssg_ds
      File.read(SSG_DS_FILE)
    end

    def ssg_ds_checksum
      Digest::MD5.file(SSG_DS_FILE).hexdigest
    end

    def update_ssg_ds
      ssg_content = download(ssg_datastream_config_url)&.read
      ssg_content && File.open(SSG_DS_FILE, 'w') do |f|
        f.write(ssg_content)
      end
    end

    def ssg_datastream_config_url
      [
        Settings.compliance_ssg_url,
        Settings.supported_ssg_ds_config
      ].join('/')
    end

    private

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
