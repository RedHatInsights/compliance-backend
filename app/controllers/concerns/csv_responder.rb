# frozen_string_literal: true

# Concern to provide basic options for CSV output
module CsvResponder
  extend ActiveSupport::Concern

  def csv_response(resources, columns, header = nil, filename = nil)
    filename ||= "#{controller_name}-#{Time.zone.today}.csv"
    headers['Cache-Control'] = 'no-cache'
    headers['Content-Type'] = 'text/csv; charset=utf-8'
    headers['Content-Disposition'] = %(attachment; filename="#{filename}")
    self.response_body = CsvExporter.export(resources, columns, header)
  end
end
