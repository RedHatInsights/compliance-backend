# frozen_string_literal: true

require 'clowder-common-ruby'

module Compliance
  class TableSizeCollector
    def self.collect
      current_tables = []

      ActiveRecord::Base.connection.execute(<<~SQL).each do |row|
        SELECT relname AS table_name, pg_total_relation_size(relid) AS size_bytes
        FROM pg_catalog.pg_statio_user_tables
        ORDER BY size_bytes DESC
      SQL
        table_name = row['table_name']
        current_tables << table_name
        Yabeda.compliance_db_table_size_bytes.set({ table: table_name }, row['size_bytes'].to_i)
      end

      # Remove metrics for tables that no longer exist (best-effort for in-memory adapters)
      # Note: In production with yabeda-prometheus-mmap, stale labels are completely purged
      # only upon container/process restart when the shared mmap .db files are cleared.
      metric = Yabeda.compliance_db_table_size_bytes
      metric.values.keys.each do |tags|
        metric.values.delete(tags) unless current_tables.include?(tags[:table])
      end
    rescue StandardError => e
      Rails.logger.error("Failed to collect DB table size metrics: #{e.full_message}")
    end
  end
end

# Metrics configuration
Yabeda.configure do
  default_tag :application, 'compliance'
  default_tag :qe, 0
  # APIv2 specific tags
  # default_tag :path, nil
  default_tag :source, 'basic'

  gauge :compliance_db_table_size_bytes,
        comment: 'Total disk space used by each database table, including indexes and TOAST',
        tags: %i[table]

  collect do
    Compliance::TableSizeCollector.collect
  end
end

# Start the metrics server for sidekiq and karafka
if %w[sidekiq karafka].any? { |p| $PROGRAM_NAME.include?(p) }
  if ClowderCommonRuby::Config.clowder_enabled?
    ENV['PROMETHEUS_EXPORTER_PORT'] = ClowderCommonRuby::Config.load.metricsPort.to_s
  else
    ENV['PROMETHEUS_EXPORTER_PORT'] ||= '9090'
  end

  Yabeda::ActiveJob.install!
  Yabeda::Prometheus::Exporter.start_metrics_server!
end
