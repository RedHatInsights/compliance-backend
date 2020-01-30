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
    end
  end
end
# rubocop:enable Metrics/BlockLength
