# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'

# Finds the files in a insights tar and returns them as an array
class ReportsTarReader
  def initialize(file)
    @file = file
  end

  def reports
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.new(@file))
    tar_extract.rewind # The extract has to be rewinded after every iteration
    tar_extract.map do |file|
      file.read if file.header.name.match(/oscap_results/)
    end.compact
  rescue Zlib::GzipFile::Error
    # Keeps on supporting --payload uploads which only contain one report
    [IO.read(@file)]
  ensure
    tar_extract.close
  end
end
