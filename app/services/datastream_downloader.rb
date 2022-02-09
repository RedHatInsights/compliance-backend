# frozen_string_literal: true

# Service for dowloading (downstream) datastream files
class DatastreamDownloader
  def initialize(ssgs = nil)
    @ssgs = ssgs || default_supported_ssgs
  end

  def default_supported_ssgs
    ::SupportedSsg.all
                  .sort_by(&:version_with_revision)
                  .reverse
                  .uniq { |ssg| [ssg.version, ssg.os_major_version] }
  end

  def download_datastreams
    Dir.mktmpdir do |tmpdir|
      datastream_urls.each do |label, url|
        filepath = File.join(tmpdir, "#{label}.xml")
        ds = download(url)
        FileUtils.cp(ds.path, filepath)
        ds.close
        yield filepath
      end
    end
  end

  def datastream_urls
    @ssgs.map do |ssg|
      [ssg.id, datastream_url(ssg)]
    end
  end

  def datastream_url(ssg)
    [
      Settings.compliance_ssg_url,
      'datastreams',
      "rhel#{ssg.os_major_version}",
      ssg.package,
      "ssg-rhel#{ssg.os_major_version}-ds.xml"
    ].join('/')
  end

  private

  def download(url)
    begin
      file = SafeDownloader.download(url)
    rescue StandardError => e
      Rails.logger.audit_fail(
        "Failed to dowload datastream file from #{url}: #{e}"
      )
      raise
    end
    Rails.logger.audit_success("Dowloaded datastream file from #{url}")
    file
  end
end
