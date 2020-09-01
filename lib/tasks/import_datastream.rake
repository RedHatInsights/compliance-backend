# frozen_string_literal: true

# Disabling BlockLength here because the namespace of a Rake job resembles more
# a class than a block and should be able to handle multiple tasks.
# rubocop:disable Metrics/BlockLength
namespace :ssg do
  desc 'Update compliance DB with the latest release of the SCAP Security Guide'
  task import_rhel: [:environment, 'ssg:sync_rhel'] do
    # DATASTREAM_FILENAMES from openscap_parser's ssg:sync_rhel
    begin
      Rails.cache.delete('latest_supported_benchmarks')
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
  end

  desc 'Update compliance DB with the supported SCAP Security Guide versions'
  task import_rhel_supported: [:environment] do
    # DATASTREAM_FILENAMES from openscap_parser's ssg:sync
    begin
      Rails.cache.delete('latest_supported_benchmarks')
      ENV['DATASTREAMS'] = ::Xccdf::Benchmark::
        LATEST_SUPPORTED_VERSIONS.map do |ref_id, version|
        "v#{version}:rhel#{ref_id[/\d+$/]}"
      end.join(',')
      Rake::Task['ssg:sync'].invoke
      DATASTREAM_FILENAMES.flatten.each do |filename|
        ENV['DATASTREAM_FILE'] = filename
        Rake::Task['ssg:import'].execute
      end
    end
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
