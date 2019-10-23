# frozen_string_literal: true

require 'test_helper'

# A class to test importing from a Datastream file
class DatastreamImporterTest < ActiveSupport::TestCase
  setup do
    DATASTREAM_FILE = file_fixture('ssg-rhel7-ds.xml')
  end

  test 'datastream import' do
    importer = DatastreamImporter.new(DATASTREAM_FILE)
    importer.expects(:save_all_benchmark_info)
    importer.import!
  end
end
