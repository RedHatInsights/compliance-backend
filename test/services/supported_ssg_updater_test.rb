# frozen_string_literal: true

require 'test_helper'

# A class to test the SupportedSsgUpdater service
class SupportedSsgUpdaterTest < ActiveSupport::TestCase
  context 'fallback file' do
    setup do
      @supported_file = ::Tempfile.new('suported_ssg_file')
      @supported_file.write(File.read('test/fixtures/files/supported_ssg_test.yaml'))
      @supported_file.rewind

      @fallback_file = ::Tempfile.new('fallback_ssg_file')
    end

    should 'contain correct yaml representation' do
      SsgConfigDownloader.stub_const(:DS_FILE_PATH, @supported_file.path) do
        SsgConfigDownloader.stub_const(:DS_FALLBACK_PATH, @fallback_file.path) do
          SupportedSsgUpdater.run!
          fallback_ssg = YAML.safe_load(@fallback_file.read)
          assert_not_empty fallback_ssg
        end
      end
    end

    should 'not contain unwanted keys' do
      SsgConfigDownloader.stub_const(:DS_FILE_PATH, @supported_file.path) do
        SsgConfigDownloader.stub_const(:DS_FALLBACK_PATH, @fallback_file.path) do
          SupportedSsgUpdater.run!

          fallback = YAML.safe_load(@fallback_file.read)

          assert fallback.dig('upstream_version').nil? && fallback.dig('brew_url').nil?
        end
      end
    end

    should 'not contain any keys in profiles (except old_names)' do
      SsgConfigDownloader.stub_const(:DS_FILE_PATH, @supported_file.path) do
        SsgConfigDownloader.stub_const(:DS_FALLBACK_PATH, @fallback_file.path) do
          SupportedSsgUpdater.run!

          fallback = YAML.safe_load(@fallback_file.read)

          def sub_keys?(profile)
            profile&.instance_of(Hash) && profile.keys.any? && profile.keys.exclude?('old_names')
          end

          SupportedSsgUpdater.search_through(fallback) do |key, value, _current_hash|
            if key == 'profiles'
              value.each do |_key, profile|
                assert_not sub_keys?(profile)
              end
            end
          end
        end
      end
    end

    teardown do
      @supported_file.close
      @supported_file.unlink
      @fallback_file.close
      @fallback_file.unlink
    end
  end
end
