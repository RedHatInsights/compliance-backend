# frozen_string_literal: true

require 'test_helper'

# A class to test importing from a Datastream file
class DatastreamImporterTest < ActiveSupport::TestCase
  setup do
    @datastream_file = file_fixture('ssg-rhel7-ds.xml')
  end

  test 'datastream import' do
    importer = DatastreamImporter.new(@datastream_file)
    importer.expects(:save_all_benchmark_info)
    importer.import!
  end

  test 'works without any accounts' do
    importer = DatastreamImporter.new(@datastream_file)
    importer.expects(:save_all_benchmark_info)
    importer.import!
  end
end
