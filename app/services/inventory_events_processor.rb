# frozen_string_literal: true

# Adapts one inventory event to the existing system jobs synchronously.
# The batch job owns ordering and failure isolation; this class owns dispatch.
class InventoryEventsProcessor
  def initialize(entry)
    @entry = entry
  end

  def process
    dispatch(@entry.fetch('type'), @entry.fetch('payload'))
  end

  private

  def dispatch(type, payload)
    case type
    when 'delete'
      SystemDeleteJob.new.perform(payload)
    when 'created', 'updated'
      SystemImportJob.new.perform(payload)
    end
  end
end
