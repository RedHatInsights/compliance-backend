# frozen_string_literal: true

require 'csv'

# Generate an Enumerator which contains all of the required rows to create a
# CSV report from a model and few columns
module CsvExporter
  LENGTH_MISMATCH = "Columns and header row aren't the same length"

  # Justification: Technical debt, this was borrowed from Foreman
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def self.export(resources, columns, header = nil)
    header ||= default_header(columns)
    raise ArgumentError, LENGTH_MISMATCH unless columns.length == header.length

    Enumerator.new do |csv|
      csv << CSV.generate_line(header)
      cols = columns.map { |c| c.to_s.split('.').map(&:to_sym) }
      resources.uncached do
        resources.reorder(nil).limit(nil).find_each do |obj|
          csv << CSV.generate_line(cols.map { |c| c.inject(obj, :try) })
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def self.default_header(columns)
    columns.map { |c| c.to_s.titleize }
  end
end
