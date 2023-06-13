# frozen_string_literal: true

# Disabling BlockLength here because the namespace of a Rake job resembles more
# a class than a block and should be able to handle multiple tasks.
# rubocop:disable Metrics/BlockLength
namespace :ssg do
  desc 'Check if the latest SSG has been synced'
  task check_synced: [:environment] do
    # SupportedSsg.revision should be force-loaded here to bypass memoizing
    if Revision.datastreams != SupportedSsg.revision(true)
      abort("SSG datastreams not synced\nDatastream config revision: " \
        "#{SupportedSsg.revision.inspect}\nDB revision: " \
        "#{Revision.datastreams.inspect}")
    end

    if Revision.remediations != SupportedRemediations.revision
      abort("SSG remediations not synced\nRemediation config revision: " \
        "#{SupportedRemediations.revision.inspect}\nDB revision: " \
        "#{Revision.remediations.inspect}")
    end

    Rails.logger.info('Datastreams and remediations synced to revision: ' \
                      "#{Revision.datastreams} and #{Revision.remediations}")
  end

  desc 'Update supported SSGs fallback yaml'
  task sync_supported: [:environment] do
    SupportedSsgUpdater.run!
    Rails.logger.info "Fallback YAML has been updated to revision: #{Revision.datastreams}"
  end

  desc 'Update compliance DB with the supported SCAP Security Guide versions'
  task import_rhel_supported: [:environment] do
    # Force an SSG import if the datastream revision is unset
    Settings.force_import_ssgs = true if Revision.datastreams.nil?

    # Force the reloading of the memoized SSG revision
    if Revision.datastreams != SupportedSsg.revision(true)
      downloader = DatastreamDownloader.new
      downloader.download_datastreams do |file|
        ENV['DATASTREAM_FILE'] = file
        Rake::Task['ssg:import'].execute
      end
      # Clear the old cached values
      SupportedSsg.clear
      # Clear the GraphQL fragment cache
      Rails.cache.delete_matched('graphql/*')
    end
    Revision.datastreams = SupportedSsg.revision
    Rails.logger.info "Datastreams synced to revision: #{Revision.datastreams}"
    Rake::Task['import_remediations'].execute
  end

  desc 'Update compliance DB with data from an Xccdf datastream file'
  task import: [:environment] do
    begin
      if (filename = ENV.fetch('DATASTREAM_FILE', nil))
        start = Time.zone.now
        Rails.logger.info "Importing #{filename} at #{start}"
        DatastreamImporter.new(filename).import!
        Rails.logger.info "Finished importing #{filename} in #{Time.zone.now - start} seconds."
      end
    rescue StandardError => e
      ExceptionNotifier.notify_exception(
        e,
        data: OpenshiftEnvironment.summary
      )
      Rails.logger.error "Import failed for #{filename} in #{Time.zone.now - start} seconds."
      raise e
    end
  end
end
# rubocop:enable Metrics/BlockLength
