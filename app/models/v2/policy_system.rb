# frozen_string_literal: true

module V2
  # Model link between Policy and System
  class PolicySystem < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :policy_systems
    self.primary_key = :id

    belongs_to :policy, class_name: 'V2::Policy'
    belongs_to :system, class_name: 'V2::System'

    validates :policy_id, presence: true
    validates :system_id, presence: true, uniqueness: { scope: :policy_id }
    validate :system_supported?, on: :create

    after_create do
      Tailoring.find_or_create_by!(policy_id: policy_id, os_minor_version: system.os_minor_version) do |tailoring|
        # Look up the latest Profile supporting the given OS minor version
        tailoring.profile = policy.profile.variant_for_minor(system.os_minor_version)

        tailoring.rules = tailoring.profile.rules # FIXME: this is inefficient
        tailoring.value_overrides = tailoring.profile.value_overrides
      end
    end

    def system_supported?
      if policy.os_major_version != system.os_major_version
        errors.add(:system, 'Unsupported OS major version')
      elsif policy.os_minor_versions.exclude?(system.os_minor_version)
        errors.add(:system, 'Unsupported OS minor version')
      end
    end
  end
end
