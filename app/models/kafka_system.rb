# frozen_string_literal: true

# Temporary model for ingesting inventory data directly to compliance db
class KafkaSystem < ApplicationRecord
  self.table_name = 'systems'

  default_scope { where(deleted_at: nil) }
end
