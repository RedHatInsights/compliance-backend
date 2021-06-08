# frozen_string_literal: true

require 'test_helper'

class SafeDownloaderTest < ActiveSupport::TestCase
  setup do
    @url = 'http://example.com'
  end

  context '#download' do
    should 'success with small file' do
      strio = StringIO.new('report')
      URI::HTTP.any_instance.expects(:open).returns(strio)

      downloaded = SafeDownloader.download(@url)
      assert_equal strio.size, downloaded.size
    end

    should 'success with large file' do
      file = File.new(file_fixture('insights-archive.tar.gz'))
      URI::HTTP.any_instance.expects(:open).returns(file)

      downloaded = SafeDownloader.download(@url)
      assert_equal file.size, downloaded.size
    end

    should 'fail with empty file' do
      URI::HTTP.any_instance.expects(:open).returns(StringIO.new)
      assert_raises(SafeDownloader::DownloadError) do
        SafeDownloader.download(@url)
      end
    end

    should 'fail with url parse failure' do
      assert_raises(SafeDownloader::DownloadError) do
        SafeDownloader.download(:bad_url)
      end
    end

    should 'download with oversized file' do
      assert_raises(SafeDownloader::DownloadError) do
        SafeDownloader.download(@url, max_size: 1)
      end
    end

    should 'raise if not https on ssl_only' do
      URI::HTTP.any_instance.expects(:open).never

      assert_raises(SafeDownloader::DownloadError) do
        SafeDownloader.download(@url, ssl_only: true)
      end
    end
  end

  context '#download_reports' do
    should 'success with small reports file' do
      strio = StringIO.new('report')
      URI::HTTP.any_instance.expects(:open).returns(strio)
      IO.expects(:read).never
      strio.expects(:string).returns('report')

      downloaded = SafeDownloader.download_reports(@url)
      assert_equal 1, downloaded.count
    end

    should 'success with large file' do
      file = File.new(file_fixture('insights-archive.tar.gz'))
      URI::HTTP.any_instance.expects(:open).returns(file)
      ReportsTarReader.any_instance.expects(:reports).returns(['report'])

      downloaded = SafeDownloader.download_reports(@url)
      assert_equal 1, downloaded.count
    end

    should 'check secure for reports url in production' do
      strio = StringIO.new('report')
      URI::HTTP.any_instance.expects(:open).returns(strio)
      Rails.env.expects(:production?).returns(true).twice

      assert_raises(SafeDownloader::DownloadError) do
        SafeDownloader.download_reports(@url)
      end

      safe_url = 'https://example.com'
      downloaded = SafeDownloader.download_reports(safe_url)
      assert_equal 1, downloaded.count
    end
  end
end
