# frozen_string_literal: true

require 'test_helper'

class SafeDownloaderTest < ActiveSupport::TestCase
  setup do
    @url = 'http://example.com'
  end

  test 'download success with small file' do
    strio = StringIO.new('a')
    URI::HTTP.any_instance.expects(:open).returns(strio)
    IO.expects(:read).never
    strio.expects(:string)

    SafeDownloader.download(@url)
  end

  test 'download success with large file' do
    file = File.new(file_fixture('insights-archive.tar.gz'))
    URI::HTTP.any_instance.expects(:open).returns(file)
    ReportsTarReader.any_instance.expects(:reports)

    SafeDownloader.download(@url)
  end

  test 'download with empty file fails' do
    URI::HTTP.any_instance.expects(:open).returns(StringIO.new)
    assert_raises(SafeDownloader::DownloadError) do
      SafeDownloader.download(@url)
    end
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
  end
end
