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
    files = []
    tar_extract.each do |entry|
      files << entry.read
    end
    tar_extract.close
    files
  rescue Zlib::GzipFile::Error
    # Keeps on supporting --payload uploads which only contain one report
    [IO.read(@file)]
  end
end
