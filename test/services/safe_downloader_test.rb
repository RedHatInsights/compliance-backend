# frozen_string_literal: true

require 'test_helper'

class SafeDownloaderTest < ActiveSupport::TestCase
  setup do
    @url = 'http://example.com'
  end

  test 'download success' do
    URI::HTTP.any_instance.expects(:open).returns(StringIO.new('a'))
    IO.expects(:read)

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
