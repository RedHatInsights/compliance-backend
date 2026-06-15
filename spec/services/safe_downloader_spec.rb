# frozen_string_literal: true

require 'rails_helper'

describe SafeDownloader do
  let(:url) { Faker::Internet.url(scheme: 'http') }
  let(:http_response) { StringIO.new(Faker::Lorem.word) }

  before do
    allow(Rails.logger).to receive(:audit_success)
    allow(Rails.logger).to receive(:audit_fail)
    allow_any_instance_of(URI::HTTP).to receive(:open).and_return(http_response)
  end

  describe '.download' do
    context 'when the response fits in memory (StringIO)' do
      it 'returns the downloaded content' do
        expect(described_class.download(url).size).to eq(http_response.size)
      end
    end

    context 'when the response is streamed to a file' do
      let(:http_response) { file_fixture('insights-archive.tar.gz').open }

      it 'returns the downloaded content' do
        expect(described_class.download(url).size).to eq(http_response.size)
      end
    end

    context 'when the response is empty' do
      let(:http_response) { StringIO.new }

      it 'raises DownloadError' do
        expect { described_class.download(url) }.to raise_error(SafeDownloader::DownloadError)
      end
    end

    context 'when the URL cannot be parsed' do
      it 'raises DownloadError' do
        expect { described_class.download(:bad_url) }.to raise_error(SafeDownloader::DownloadError)
      end
    end

    context 'when the download exceeds the size limit' do
      before do
        allow_any_instance_of(URI::HTTP).to receive(:open)
          .and_raise(SafeDownloader::DownloadError, 'file is too big')
      end

      it 'raises DownloadError' do
        expect { described_class.download(url, max_size: 1) }.to raise_error(SafeDownloader::DownloadError)
      end
    end

    context 'when ssl_only is true and the URL scheme is not HTTPS' do
      it 'raises DownloadError without opening the connection' do
        expect_any_instance_of(URI::HTTP).not_to receive(:open)

        expect { described_class.download(url, ssl_only: true) }.to raise_error(SafeDownloader::DownloadError)
      end
    end
  end

  describe '.download_reports' do
    context 'when the response fits in memory (StringIO)' do
      it 'returns the string content as a single-element array' do
        expect(described_class.download_reports(url)).to eq([http_response.string])
      end
    end

    context 'when the response is a tar archive' do
      let(:http_response) { file_fixture('insights-archive.tar.gz').open }
      let(:reports) { Array.new(Faker::Number.between(from: 1, to: 5)) { Faker::Lorem.word } }

      before do
        allow_any_instance_of(ReportsTarReader).to receive(:reports).and_return(reports)
      end

      it 'delegates extraction to ReportsTarReader' do
        expect(described_class.download_reports(url)).to eq(reports)
      end
    end

    context 'when ssl_only is true and the URL scheme is not HTTPS' do
      it 'raises DownloadError without opening the connection' do
        expect_any_instance_of(URI::HTTP).not_to receive(:open)

        expect { described_class.download_reports(url, ssl_only: true) }
          .to raise_error(SafeDownloader::DownloadError)
      end
    end
  end
end
