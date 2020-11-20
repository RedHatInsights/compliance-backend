# frozen_string_literal: true

# Disabling BlockLength here because the namespace of a Rake job resembles more
# a class than a block and should be able to handle multiple tasks.
# rubocop:disable Metrics/BlockLength
namespace :ssg do
  desc 'Update compliance DB with the latest release of the SCAP Security Guide'
  task import_rhel: [:environment, 'ssg:sync_rhel'] do
    # DATASTREAM_FILENAMES from openscap_parser's ssg:sync_rhel
    begin
      DATASTREAM_FILENAMES.flatten.each do |filename|
        start = Time.zone.now
        puts "Importing #{filename} at #{start}"
        DatastreamImporter.new(filename).import!
        puts "Finished importing #{filename} in #{Time.zone.now - start}"\
             ' seconds.'
      end
    rescue StandardError => e
      ExceptionNotifier.notify_exception(
        e,
        data: OpenshiftEnvironment.summary
      )
    end
    Rails.cache.delete('latest_supported_benchmarks')
  end

  desc 'Update compliance DB with the supported SCAP Security Guide versions'
  task import_rhel_supported: [:environment] do
    # DATASTREAM_FILENAMES from openscap_parser's ssg:sync
    ENV['DATASTREAMS'] = ::SupportedSsg.available_upstream.map do |ssg|
      "v#{ssg.upstream_version || ssg.version}:rhel#{ssg.os_major_version}"
    end.uniq.join(',')
    Rake::Task['ssg:sync'].invoke
    DATASTREAM_FILENAMES.flatten.each do |filename|
      ENV['DATASTREAM_FILE'] = filename
      Rake::Task['ssg:import'].execute
    end
    Rails.cache.delete('latest_supported_benchmarks')
  end

  desc 'Update compliance DB with data from an Xccdf datastream file'
  task import: [:environment] do
    begin
      if (filename = ENV['DATASTREAM_FILE'])
        start = Time.zone.now
        puts "Importing #{filename} at #{start}"
        DatastreamImporter.new(filename).import!
        puts "Finished importing #{filename} in #{Time.zone.now - start}"\
             ' seconds.'
      end
    rescue StandardError => e
      ExceptionNotifier.notify_exception(
        e,
        data: OpenshiftEnvironment.summary
      )
      puts "Import failed for #{filename} in #{Time.zone.now - start} seconds."
      raise e
    end
  end
end
# rubocop:enable Metrics/BlockLength
