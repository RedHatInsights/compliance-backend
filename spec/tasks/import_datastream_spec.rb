# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'ssg tasks' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  let(:current_date) { Time.zone.now.to_date.to_s }
  let(:old_date) { 1.day.ago.to_date.to_s }

  def suppress_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = original_stderr
  end

  describe 'ssg:check_synced' do
    before do
      allow(Rails.logger).to receive(:info)
    end

    context 'both datastreams and remediations are synced' do
      before do
        allow(Revision).to receive(:datastreams).and_return(current_date)
        allow(SupportedSsg).to receive(:revision).and_return(current_date)

        allow(Revision).to receive(:remediations).and_return(current_date)
        allow(SupportedRemediations).to receive(:revision).and_return(current_date)
      end

      it 'does not raise an error' do
        expect { Rake::Task['ssg:check_synced'].execute }.not_to raise_error

        expect(Rails.logger).to have_received(:info).with('Datastreams and remediations synced to revision: ' \
                                                          "#{current_date} and #{current_date}")
      end
    end

    context 'datastreams and remediations are synced but have different revision dates' do
      before do
        allow(Revision).to receive(:datastreams).and_return(current_date)
        allow(SupportedSsg).to receive(:revision).and_return(current_date)

        allow(Revision).to receive(:remediations).and_return(old_date)
        allow(SupportedRemediations).to receive(:revision).and_return(old_date)
      end

      it 'does not raise an error' do
        expect { Rake::Task['ssg:check_synced'].execute }.not_to raise_error

        expect(Rails.logger).to have_received(:info).with(
          'Datastreams and remediations synced to revision: ' \
          "#{current_date} and #{old_date}"
        )
      end
    end

    context 'datastreams are not synced, remediations are' do
      before do
        allow(Revision).to receive(:datastreams).and_return(current_date)
        allow(SupportedSsg).to receive(:revision).and_return(old_date)

        allow(Revision).to receive(:remediations).and_return(current_date)
        allow(SupportedRemediations).to receive(:revision).and_return(current_date)
      end

      it 'raises an error' do
        suppress_stderr do
          expect { Rake::Task['ssg:check_synced'].execute }.to raise_error(
            SystemExit, "SSG datastreams not synced\n" \
            "Datastream config revision: #{old_date.inspect}\nDB revision: #{current_date.inspect}"
          )
        end
      end
    end

    context 'datastreams are synced, remediations are not' do
      before do
        allow(Revision).to receive(:datastreams).and_return(current_date)
        allow(SupportedSsg).to receive(:revision).and_return(current_date)

        allow(Revision).to receive(:remediations).and_return(current_date)
        allow(SupportedRemediations).to receive(:revision).and_return(old_date)
      end

      it 'raises an error' do
        suppress_stderr do
          expect { Rake::Task['ssg:check_synced'].execute }.to \
            raise_error(SystemExit, "SSG remediations not synced\n" \
            "Remediation config revision: #{old_date.inspect}\nDB revision: #{current_date.inspect}")
        end
      end
    end

    context 'neither datastreams, nor remediations are synced' do
      before do
        allow(Revision).to receive(:datastreams).and_return(current_date)
        allow(SupportedSsg).to receive(:revision).and_return(old_date)

        allow(Revision).to receive(:remediations).and_return(current_date)
        allow(SupportedRemediations).to receive(:revision).and_return(old_date)
      end

      it 'raises an error' do
        suppress_stderr do
          expect { Rake::Task['ssg:check_synced'].execute }.to raise_error(
            SystemExit, "SSG datastreams not synced\n" \
            "Datastream config revision: #{old_date.inspect}\nDB revision: #{current_date.inspect}"
          )
        end
      end
    end
  end

  describe 'ssg:sync_supported' do
    before do
      allow(Revision).to receive(:datastreams).and_return(current_date)
      allow(SupportedSsgUpdater).to receive(:run!)
      allow(Rails.logger).to receive(:info)
    end

    it 'calls the SupportedSsgUpdater' do
      expect { Rake::Task['ssg:sync_supported'].execute }.not_to raise_error

      expect(SupportedSsgUpdater).to have_received(:run!)
      expect(Rails.logger).to have_received(:info).with(
        "Fallback YAML has been updated to revision: #{current_date}"
      )
    end
  end

  describe 'ssg:import_rhel_supported' do
    let(:downloader) { instance_double(DatastreamDownloader) }

    before do
      allow(Rake::Task['ssg:import']).to receive(:execute)
      allow(Rake::Task['import_remediations']).to receive(:execute)
      allow(SupportedSsg).to receive(:clear)

      allow(SupportedSsg).to receive(:revision).with(true).and_return(current_date)
      allow(SupportedSsg).to receive(:revision).with(no_args).and_return(current_date)

      allow(DatastreamDownloader).to receive(:new).and_return(downloader)
      allow(downloader).to receive(:download_datastreams).and_yield('file1').and_yield('file2')
    end

    context 'when the datastream revision is unset' do
      before do
        datastreams_revision = nil
        allow(Revision).to receive(:datastreams) { datastreams_revision }
        allow(Revision).to receive(:datastreams=) { |val| datastreams_revision = val }
      end

      it 'forces an SSG import' do
        without_partial_double_verification do
          expect(Settings).to receive(:force_import_ssgs=).with(true)
        end
        expect(downloader).to receive(:download_datastreams).and_yield('file1').and_yield('file2')

        expect(Rake::Task['ssg:import']).to receive(:execute).twice do
          expect(%w[file1 file2]).to include(ENV.fetch('DATASTREAM_FILE', nil))
        end

        expect(SupportedSsg).to receive(:clear)

        expect(Revision).to receive(:datastreams=).with(current_date)
        expect(Rails.logger).to receive(:info).with("Datastreams synced to revision: #{current_date}")
        expect(Rake::Task['import_remediations']).to receive(:execute)

        Rake::Task['ssg:import_rhel_supported'].execute
      end
    end

    context 'when datastreams need update' do
      before do
        datastreams_revision = old_date
        allow(Revision).to receive(:datastreams) { datastreams_revision }
        allow(Revision).to receive(:datastreams=) { |val| datastreams_revision = val }
      end

      it 'imports downstream datastreams and updates revision' do
        without_partial_double_verification do
          expect(Settings).to_not receive(:force_import_ssgs=).with(true)
        end
        expect(downloader).to receive(:download_datastreams).and_yield('file1').and_yield('file2')

        expect(Rake::Task['ssg:import']).to receive(:execute).twice do
          expect(%w[file1 file2]).to include(ENV.fetch('DATASTREAM_FILE', nil))
        end
        expect(SupportedSsg).to receive(:clear)

        expect(Revision).to receive(:datastreams=).with(current_date)
        expect(Rails.logger).to receive(:info).with("Datastreams synced to revision: #{current_date}")
        expect(Rake::Task['import_remediations']).to receive(:execute)

        Rake::Task['ssg:import_rhel_supported'].execute
      end
    end
  end

  describe 'ssg:import' do
    let(:filename) { 'spec/fixtures/files/ssg-rhel7-ds.xml' }
    let(:importer) { instance_double(DatastreamImporter) }
    let(:start_time) { Time.zone.now }

    before do
      allow(ENV).to receive(:fetch).with('DATASTREAM_FILE', nil).and_return(filename)
      allow(Time.zone).to receive(:now).and_return(start_time)
      allow(DatastreamImporter).to receive(:new).with(filename).and_return(importer)
      allow(importer).to receive(:import!)
    end

    it 'imports the file' do
      expect(Rails.logger).to receive(:info).with("Importing #{filename} at #{start_time}")
      expect(importer).to receive(:import!)
      expect(Rails.logger).to receive(:info).with(
        "Finished importing #{filename} in #{Time.zone.now - start_time} seconds."
      )

      Rake::Task['ssg:import'].execute
    end

    context 'when an exception is raised' do
      before do
        allow(importer).to receive(:import!).and_raise(StandardError, 'import failed')
        allow(ExceptionNotifier).to receive(:notify_exception)
        allow(OpenshiftEnvironment).to receive(:summary).and_return({})
      end

      it 'propagates and logs errors' do
        expect(ExceptionNotifier).to receive(:notify_exception)
        expect(Rails.logger).to receive(:error).with(
          "Import failed for #{filename} in #{Time.zone.now - start_time} seconds."
        )

        expect { Rake::Task['ssg:import'].execute }.to raise_error(StandardError, 'import failed')
      end
    end

    context 'when the filename is not set' do
      before do
        allow(ENV).to receive(:fetch).with('DATASTREAM_FILE', nil).and_return(nil)
      end

      it 'does nothing silently' do
        expect { Rake::Task['ssg:import'].execute }.not_to raise_error
      end
    end
  end
end
