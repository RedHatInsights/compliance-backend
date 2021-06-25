# frozen_string_literal: true

require 'test_helper'

# A class to test the SsgConfigDownloader service
class ConfigDownloaderTest < ActiveSupport::TestCase
  setup do
    @ds_config_file = File.new('config/supported_ssg.yaml')
  end

  test 'ssg_ds returns SSG datastream config file from disk' do
    assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
  end

  test 'ssg_ds_checksum' do
    assert_equal Digest::MD5.file(@ds_config_file).hexdigest,
                 SsgConfigDownloader.ssg_ds_checksum
  end

  test 'update_ssg_ds success' do
    SafeDownloader.expects(:download)

    SsgConfigDownloader.update_ssg_ds
    assert_audited 'Downloaded config'

    assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
  end

  test 'update_ssg_ds handles failure gracefully' do
    SafeDownloader.expects(:download).raises(StandardError)

    SsgConfigDownloader.update_ssg_ds
    assert_audited 'Failed to download config'

    assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
  end
end
