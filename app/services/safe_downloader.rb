# frozen_string_literal: true

require 'open-uri'
require 'net/http'

# Service used to download reports or anything else. It includes
# protection against the infamous open('| ls')
class SafeDownloader
  DownloadError = Class.new(StandardError)
  # Exception class to handle empty reports
  class EmptyFileError < StandardError
    def initialize(message = 'file is empty')
      super(message)
    end
  end

  DOWNLOAD_ERRORS = [
    SocketError,
    OpenURI::HTTPError,
    RuntimeError,
    URI::InvalidURIError,
    DownloadError,
    EmptyFileError
  ].freeze

  class << self
    def download(url, max_size: nil, ssl_only: false)
      uri = encode_url(url, ssl_only)
      downloaded_file = open_url(uri, create_options(max_size))
      raise EmptyFileError if downloaded_file.size.zero?

      downloaded_file
    rescue *DOWNLOAD_ERRORS => e
      raise DownloadError if e.instance_of?(RuntimeError) &&
                             e.message !~ /redirection/

      raise DownloadError, "download failed (#{url}): #{e.message}"
    end

    def download_reports(url, opts = {})
      begin
        downloaded_file = download(url, opts)
      rescue *DOWNLOAD_ERRORS
        Rails.logger.audit_fail("Failed to download report from URL: #{url}")
        raise
      end

      Rails.logger.audit_success("Downloaded report from URL: #{url}")
      report_contents(downloaded_file)
    end

    private

    def report_contents(downloaded_file)
      case downloaded_file
      when StringIO
        [downloaded_file.string]
      else
        ReportsTarReader.new(downloaded_file).reports
      end
    end

    def open_url(url, options)
      url.open(options)
    end

    def encode_url(url, ssl_only)
      url = URI(url)
      check_url(url, ssl_only)
      url
    rescue ArgumentError
      raise DownloadError, 'url was invalid'
    end

    def check_url(url, ssl_only)
      raise DownloadError, 'url was invalid' unless url.respond_to?(:open)

      return unless ssl_only && url.scheme != 'https'

      raise DownloadError, 'not secure (non-https)'
    end

    def create_options(max_size)
      options = {}
      options['User-Agent'] = 'Red Hat Insights: Compliance'
      options[:content_length_proc] = lambda do |size|
        if max_size && size && size > max_size
          raise DownloadError, "file is too big (max is #{max_size})"
        end
      end
      options
    end
  end
end
