# frozen_string_literal: true

module V2
  # Class representing read-only systems syndicated from the host-based inventory
  class System < ApplicationRecord
    belongs_to :account, class_name: 'V2::Account', foreign_key: :org_id, inverse_of: :systems
    has_many :policy_systems, class_name: 'V2::PolicySystem', dependent: nil
    has_many :policies, through: :policy_systems

    # :nocov:
    def readonly?
      true
    end
    # :nocov:
  end
end
