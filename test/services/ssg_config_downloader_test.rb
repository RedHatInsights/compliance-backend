# frozen_string_literal: true

require 'test_helper'

# A class to test the SsgConfigDownloader service
class ConfigDownloaderTest < ActiveSupport::TestCase
  context 'fallback file' do
    setup do
      if File.exist?(SsgConfigDownloader::FILE_PATH)
        File.delete(SsgConfigDownloader::FILE_PATH)
      end

      @ds_config_file = File.new(SsgConfigDownloader::FALLBACK_PATH)
    end

    should 'ssg_ds returns SSG datastream fallback file from disk' do
      assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
    end

    should 'ssg_ds_checksum' do
      assert_equal Digest::MD5.file(@ds_config_file).hexdigest,
                   SsgConfigDownloader.ssg_ds_checksum
    end
  end

  context 'downloaded file' do
    setup do
      FileUtils.cp(
        SsgConfigDownloader::FALLBACK_PATH,
        SsgConfigDownloader::FILE_PATH
      )

      @ds_config_file = File.new(SsgConfigDownloader::FILE_PATH)
    end

    should 'ssg_ds returns SSG datastream file from disk' do
      assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
    end

    should 'ssg_ds_checksum' do
      assert_equal Digest::MD5.file(@ds_config_file).hexdigest,
                   SsgConfigDownloader.ssg_ds_checksum
    end

    should 'update_ssg_ds success' do
      SafeDownloader.expects(:download)

      SsgConfigDownloader.update_ssg_ds
      assert_audited 'Downloaded config'

      assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
    end

    should 'update_ssg_ds handles failure gracefully' do
      SafeDownloader.expects(:download).raises(StandardError)

      SsgConfigDownloader.update_ssg_ds
      assert_audited 'Failed to download config'

      assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
    end

    teardown do
      if File.exist?(SsgConfigDownloader::FILE_PATH)
        File.delete(SsgConfigDownloader::FILE_PATH)
      end
    end
  end
end
