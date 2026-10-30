# frozen_string_literal: true

class InventoryEventsProcessor
  def initialize(entry, attempt:)
    @entry = entry
    @attempt = attempt
  end

  def process
    case @entry.fetch('type')
    when 'delete'
      SystemDeleteJob.new(payload, metadata).perform(payload, metadata)
    when 'created', 'updated'
      job = SystemImportJob.new(payload, metadata)
      job.exception_executions = { SystemImportJob::DATABASE_RETRY_HANDLER => 2 } if @attempt == 3
      job.perform(payload, metadata)
    else
      if payload.dig('platform_metadata', 'service') == 'compliance'
        Kafka::ReportParser.new(payload, Rails.logger).parse_reports
      else
        Rails.logger.debug "Skipped message of type '#{@entry.fetch('type')}'"
      end
    end
  end

  def system_id
    id = case @entry.fetch('type')
         when 'delete' then payload['id']
         when 'created', 'updated' then payload.dig('host', 'id')
         else payload.dig('host', 'id') if payload.dig('platform_metadata', 'service') == 'compliance'
         end

    id.presence
  end

  private

  def payload
    @entry.fetch('payload')
  end

  def metadata
    @entry.fetch('metadata')
  end
end
