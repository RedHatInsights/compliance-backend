# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'

# Finds the files in a insights tar and returns them as an array
class ReportsTarReader
  def initialize(file)
    @file = file
  end

  def reports
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(@file))
    tar_extract.rewind # The extract has to be rewinded after every iteration
    tar_extract.reduce([]) { |entry, files| files << entry.read }
  rescue Zlib::GzipFile::Error
    # Keeps on supporting --payload uploads which only contain one report
    [IO.read(@file)]
  ensure
    tar_extract.close
  end
end
