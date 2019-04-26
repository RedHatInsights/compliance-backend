# frozen_string_literal: true

require 'test_helper'

class SafeDownloaderTest < ActiveSupport::TestCase
  setup do
    @url = 'http://example.com'
    @path = 'test/path'
  end

  test 'download success' do
    URI::HTTP.any_instance.expects(:open)
    Tempfile.expects(:create).with(@path).returns(OpenStruct.new(path: nil))
    IO.expects(:copy_stream)

    SafeDownloader.download(@url, @path)
  end

  test 'download with url parse failure' do
    assert_raises(SafeDownloader::DownloadError) do
      SafeDownloader.download(:bad_url, @path)
    end
  end

  test 'download with oversized file' do
    assert_raises(SafeDownloader::DownloadError) do
      SafeDownloader.download(@url, @path, max_size: 1)
    end
  end
end
