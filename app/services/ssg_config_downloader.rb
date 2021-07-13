# frozen_string_literal: true

# Service for dowloading SSG configuration files
class SsgConfigDownloader
  FILE_PATH = 'config/supported_ssg.yaml'
  FALLBACK_PATH = 'config/supported_ssg.default.yaml'

  class << self
    def ssg_ds
      File.read(ssg_ds_file)
    end

    def ssg_ds_checksum
      Digest::MD5.file(ssg_ds_file).hexdigest
    end

    def update_ssg_ds
      ssg_content = download(ssg_datastream_config_url)&.read
      ssg_content && File.open(FILE_PATH, 'w') do |f|
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

    def ssg_ds_file
      File.new(File.exist?(FILE_PATH) ? FILE_PATH : FALLBACK_PATH)
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
