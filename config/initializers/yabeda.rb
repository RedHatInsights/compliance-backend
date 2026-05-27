require 'clowder-common-ruby'

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
    ActiveRecord::Base.connection.execute(<<~SQL).each do |row|
      SELECT relname AS table_name, pg_total_relation_size(relid) AS size_bytes
      FROM pg_catalog.pg_statio_user_tables
      ORDER BY size_bytes DESC
    SQL
      compliance_db_table_size_bytes.set({ table: row['table_name'] }, row['size_bytes'].to_i)
    end
  rescue StandardError => e
    Rails.logger.error("Failed to collect DB table size metrics: #{e.message}")
  end
end

# Start the metrics server for sidekiq and karafka
if %w[sidekiq karafka].any? { |p| $0.include?(p) }
  if ClowderCommonRuby::Config.clowder_enabled?
    ENV['PROMETHEUS_EXPORTER_PORT'] = ClowderCommonRuby::Config.load.metricsPort.to_s
  else
    ENV['PROMETHEUS_EXPORTER_PORT'] ||= '9090'
  end

  Yabeda::ActiveJob.install!
  Yabeda::Prometheus::Exporter.start_metrics_server!
end
