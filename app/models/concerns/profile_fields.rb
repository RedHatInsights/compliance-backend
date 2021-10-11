# frozen_string_literal: true

# Computed Fields of a Profile
module ProfileFields
  extend ActiveSupport::Concern

  included do
    def ssg_version
      benchmark.version
    end

    def policy_type
      (parent_profile || self).name
    end

    def major_os_version
      benchmark&.inferred_os_major_version
    end
    alias_method :os_major_version, :major_os_version

    def os_version
      if os_minor_version.present?
        "#{os_major_version}.#{os_minor_version}"
      else
        os_major_version.to_s
      end
    end

    def canonical?
      parent_profile_id.blank?
    end
  end
end
