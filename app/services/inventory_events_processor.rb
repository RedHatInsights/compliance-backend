# frozen_string_literal: true

# Adapts one inventory event to the existing system jobs synchronously.
# The batch job owns ordering and failure isolation; this class owns dispatch.
class InventoryEventsProcessor
  def initialize(entry, attempt: 1)
    @entry = entry
    @attempt = attempt
  end

  def process
    dispatch(@entry.fetch('type'), @entry.fetch('payload'))
  end

  private

  def dispatch(type, payload)
    case type
    when 'delete'
      delete(payload)
    when 'created', 'updated'
      import(payload)
    end
  end

  def delete(payload)
    SystemDeleteJob.new.perform(payload)
  end

  def import(payload)
    job = SystemImportJob.new
    job.exception_executions = { SystemImportJob::DATABASE_RETRY_HANDLER => @attempt - 1 }
    job.perform(payload)
  end
end
