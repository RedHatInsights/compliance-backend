# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'

# Finds the files in a insights tar and returns them as an array
class ReportsTarReader
  LONG_LINK = '././@LongLink'
  REPORT_REGEX = %r{oscap_results[^/]+\.xml$}

  def initialize(file)
    @file = file
  end

  def reports
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.new(@file))
    tar_extract.rewind # The extract has to be rewinded after every iteration

    tar_extract.filter_map do |entry|
      filename = resolve_filename(entry)
      entry.read if filename&.match?(REPORT_REGEX)
    end
  rescue Zlib::GzipFile::Error
    # Keeps on supporting --payload uploads which only contain one report
    [IO.read(@file)]
  ensure
    @file.close
  end

  private

  # GNU tar uses a ././@LongLink pseudo-entry to support filenames longer than
  # 99 characters. Its body contains the real filename for the next entry.
  # Inspired by:
  # https://gist.github.com/ForeverZer0/2adbba36fd452738e7cca6a63aee2f30
  def resolve_filename(entry)
    if entry.full_name == LONG_LINK
      @long_link = entry.read.strip
      return nil
    end

    name = @long_link || entry.header.name
    @long_link = nil
    name
  end
end
