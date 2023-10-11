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

    tar_extract.map do |file|
      # A long link can serve as an alternative to the next entry in order to
      # support filenames longer than 99+\0 characters. In order to catch these
      # the long links are parsed as a side-effect into an instance variable
      # and their value is then used in the filename matching as an alternative.
      #
      # Inspired by:
      # https://gist.github.com/ForeverZer0/2adbba36fd452738e7cca6a63aee2f30
      next if long_link?(file)

      file.read if match_file?(file)
    end.compact
  rescue Zlib::GzipFile::Error
    # Keeps on supporting --payload uploads which only contain one report
    [IO.read(@file)]
  ensure
    @file.close
  end

  private

  def long_link?(file)
    @long_link = file.read.strip if file.full_name == LONG_LINK
  end

  def match_file?(file)
    # First try to match the filename from the long link if available
    return @long_link.match(REPORT_REGEX) if @long_link

    file.header.name.match(REPORT_REGEX)
  ensure # long link has to be empty for the next iteration if consumed
    @long_link = nil
  end
end
