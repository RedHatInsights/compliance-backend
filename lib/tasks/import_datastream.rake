# frozen_string_literal: true

# Disabling BlockLength here because the namespace of a Rake job resembles more
# a class than a block and should be able to handle multiple tasks.
# rubocop:disable Metrics/BlockLength
namespace :ssg do
  desc 'Check if the latest SSG has been synced'
  task check_synced: [:environment] do
    datastreams_message = "SSG datastreams not synced\nDatastream config revision: " \
      "#{SupportedSsg.revision.inspect}\nDB revision: " \
      "#{Revision.datastreams.inspect}"
    remediations_message = "SSG remediations not synced\nRemediation config revision: " \
      "#{SupportedSsg.revision.inspect}\nDB revision: " \
      "#{Revision.remediations.inspect}"
    abort datastreams_message if Revision.datastreams != SupportedSsg.revision
    abort remediations_message if Revision.remediations != SupportedSsg.revision
    puts "Datastreams synced to revision: #{Revision.datastreams}"
  end

  desc 'Update supported SSGs fallback yaml'
  task sync_supported: [:environment] do
    SupportedSsgUpdater.run!
    puts "Fallback YAML has been updated to revision: #{Revision.datastreams}"
  end

  desc 'Update compliance DB with the supported SCAP Security Guide versions'
  task import_rhel_supported: [:environment] do
    # Force an SSG import if the datastream revision is unset
    Settings.force_import_ssgs = true if Revision.datastreams.nil?

    if Revision.datastreams != SupportedSsg.revision
      downloader = DatastreamDownloader.new
      downloader.download_datastreams do |file|
        ENV['DATASTREAM_FILE'] = file
        Rake::Task['ssg:import'].execute
      end
    end
    Revision.datastreams = SupportedSsg.revision
    puts "Datastreams synced to revision: #{Revision.datastreams}"
    Rake::Task['import_remediations'].execute
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
