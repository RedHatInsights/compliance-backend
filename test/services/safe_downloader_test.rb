# frozen_string_literal: true

require 'test_helper'

class SafeDownloaderTest < ActiveSupport::TestCase
  setup do
    @url = 'http://example.com'
  end

  test 'download success with small file' do
    strio = StringIO.new('report')
    URI::HTTP.any_instance.expects(:open).returns(strio)
    IO.expects(:read).never
    strio.expects(:string).returns('report')

    downloaded = SafeDownloader.download(@url)
    assert_equal 1, downloaded.count
    assert_audited 'Downloaded report'
  end

  test 'download success with large file' do
    file = File.new(file_fixture('insights-archive.tar.gz'))
    URI::HTTP.any_instance.expects(:open).returns(file)
    ReportsTarReader.any_instance.expects(:reports).returns(['report'])

    downloaded = SafeDownloader.download(@url)
    assert_equal 1, downloaded.count
    assert_audited 'Downloaded report'
  end

  test 'download with empty file fails' do
    URI::HTTP.any_instance.expects(:open).returns(StringIO.new)
    assert_raises(SafeDownloader::DownloadError) do
      SafeDownloader.download(@url)
    end
    assert_audited 'Downloaded report'
  end

  test 'download with url parse failure' do
    assert_raises(SafeDownloader::DownloadError) do
      SafeDownloader.download(:bad_url)
    end
  end

  test 'download with oversized file' do
    assert_raises(SafeDownloader::DownloadError) do
      SafeDownloader.download(@url, max_size: 1)
    end
    assert_audited 'Failed to dowload report'
  end

  test 'checks secured url in production' do
    strio = StringIO.new('report')
    URI::HTTP.any_instance.expects(:open).returns(strio)
    Rails.env.expects(:production?).returns(true).twice

    assert_raises(SafeDownloader::DownloadError) do
      SafeDownloader.download(@url)
    end

    safe_url = 'https://example.com'
    downloaded = SafeDownloader.download(safe_url)
    assert_equal 1, downloaded.count
  end
end
