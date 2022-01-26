# frozen_string_literal: true

# Methods that are related to cloning non-canonical profiles
module ProfileCloning
  extend ActiveSupport::Concern

  included do
    def fill_from_parent
      self.ref_id = parent_profile.ref_id
      self.benchmark_id = parent_profile.benchmark_id
      self.name ||= parent_profile.name
      self.description ||= parent_profile.description

      self
    end

    def clone_to(account:, policy:,
                 os_minor_version: nil, set_os_minor_version: nil)
      new_profile = in_account(
        account, policy,
        os_minor_version || set_os_minor_version
      )
      new_profile ||= create_child_profile(account, policy)

      if set_os_minor_version
        # Update the os minor version if not already set
        new_profile.update_os_minor_version(set_os_minor_version)
      end
      new_profile
    end

    private

    def create_child_profile(account, policy)
      new_profile = dup
      new_profile.update!(account: account, parent_profile: self,
                          external: true, policy: policy)
      new_profile.update_rules(ref_ids: rules.pluck(:ref_id))

      Rails.logger.audit_success(%(
        Created profile #{new_profile.id} from canonical profile #{id}
        under policy #{policy&.id}
      ).gsub(/\s+/, ' ').strip)

      new_profile
    end
  end
end
