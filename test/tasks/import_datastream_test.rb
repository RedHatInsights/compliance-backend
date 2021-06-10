# frozen_string_literal: true

require 'test_helper'
require 'rake'

class ImportDatastreamTest < ActiveSupport::TestCase
  test 'ssg:import fails on error' do
    filepath = 'test/fixtures/files/xccdf_report.xml'

    ENV['DATASTREAM_FILE'] = filepath

    DatastreamImporter.any_instance.expects(:import!).raises(StandardError)

    assert_raises StandardError do
      capture_io do
        Rake::Task['ssg:import'].execute
      end
    end
  end

  test 'ssg:import_rhel_supported imports downstream datastreams' do
    DatastreamDownloader.any_instance
                        .expects(:download_datastreams)
                        .multiple_yields(['file1'], ['file2'])

    Rake::Task['ssg:import'].stubs(:execute)
    Rake::Task['ssg:import'].expects(:execute).with do
      ENV['DATASTREAM_FILE'] == 'file1'
    end
    Rake::Task['ssg:import'].expects(:execute).with do
      ENV['DATASTREAM_FILE'] == 'file2'
    end

    Rake::Task['import_remediations'].expects(:execute)

    capture_io do
      Rake::Task['ssg:import_rhel_supported'].execute
    end
  end
end
