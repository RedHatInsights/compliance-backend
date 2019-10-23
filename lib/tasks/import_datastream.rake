# frozen_string_literal: true

namespace :ssg do
  desc 'Update compliance DB with the latest release of the SCAP Security Guide'
  task import_rhel: [:environment, 'ssg:sync_rhel'] do
    # DATASTREAM_FILENAMES from openscap_parser's ssg:sync_rhel
    DATASTREAM_FILENAMES.flatten.each do |filename|
      start = Time.zone.now
      puts "Importing #{filename} at #{start}"
      DatastreamImporter.new(filename).import!
      puts "Finished importing #{filename} in #{Time.zone.now - start} seconds."
    end
  end

  desc 'Update compliance DB with data from an Xccdf datastream file'
  task import: [:environment] do
    if (filename = ENV['DATASTREAM_FILE'])
      start = Time.zone.now
      puts "Importing #{filename} at #{start}"
      DatastreamImporter.new(filename).import!
      puts "Finished importing #{filename} in #{Time.zone.now - start} seconds."
    end
  end
end
