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
      #
      # LIMITATION NOTE (Multi-Process / mmap-backed environment):
      # In production, we use `yabeda-prometheus-mmap` which stores values in shared memory-mapped
      # files (under `/tmp/*.db`). The underlying `prometheus-client-mmap` gem does not natively
      # support deleting specific label sets/keys from these .db files while the application is running.
      # Calling `metric.values.delete` only removes the key from the local worker's in-memory hash.
      # To prevent dropped tables from continuing to report their last-known non-zero size in Grafana
      # indefinitely, we explicitly set their value to 0 first. This forces the metric in scrapes to 0
      # until the shared mmap files are fully wiped/regenerated on the next pod restart (during deployment).
      metric = Yabeda.compliance_db_table_size_bytes
      metric.values.keys.each do |tags|
        unless current_tables.include?(tags[:table])
          metric.set(tags, 0)
          metric.values.delete(tags)
        end
      end
    rescue StandardError => e
      Rails.logger.error("Failed to collect DB table size metrics: #{e.full_message}")
    end
  end

  class GoodJobQueueDepthCollector
    def self.collect
      return unless defined?(GoodJob::Job)

      current_queues = []

      GoodJob::Job.where(finished_at: nil).group(:queue_name).count.each do |queue, count|
        queue_name = queue || 'default'
        current_queues << queue_name
        Yabeda.good_job_queue_depth.set({ queue: queue_name }, count)
      end

      # See the LIMITATION NOTE on TableSizeCollector for why stale entries are
      # zeroed before being purged from the local in-memory hash.
      metric = Yabeda.good_job_queue_depth
      metric.values.keys.each do |tags|
        unless current_queues.include?(tags[:queue])
          metric.set(tags, 0)
          metric.values.delete(tags)
        end
      end
    rescue StandardError => e
      Rails.logger.error("Failed to collect GoodJob queue depth metrics: #{e.message}")
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

  gauge :good_job_queue_depth,
        comment: 'Number of unfinished jobs in the GoodJob queue',
        tags: %i[queue]

  collect do
    Compliance::TableSizeCollector.collect
    Compliance::GoodJobQueueDepthCollector.collect
  end
end

# Start the metrics server for sidekiq, karafka, and good_job
if %w[sidekiq karafka good_job].any? { |p| $PROGRAM_NAME.include?(p) }
  if ClowderCommonRuby::Config.clowder_enabled?
    ENV['PROMETHEUS_EXPORTER_PORT'] = ClowderCommonRuby::Config.load.metricsPort.to_s
  else
    ENV['PROMETHEUS_EXPORTER_PORT'] ||= '9090'
  end

  Yabeda::ActiveJob.install!
  Yabeda::Prometheus::Exporter.start_metrics_server!
end
