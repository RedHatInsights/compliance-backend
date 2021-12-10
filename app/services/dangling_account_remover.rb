# frozen_string_literal: true

# Service for removing dangling accounts
class DanglingAccountRemover
  class << self
    def run!
      Account.connection.execute(deleter_arel.to_sql)
      User.delete_all
    end

    private

    def deleter_arel
      deleter = Arel::DeleteManager.new
      deleter.from(Account.arel_table).where(
        Account.arel_table[:id].not_in(
          accounts_with_profiles_or_policies
        ).and(
          Account.arel_table[:account_number].not_in(accounts_with_hosts)
        )
      )
      deleter
    end

    def accounts_with_profiles_or_policies
      Arel::Nodes::Union.new(
        Policy.arel_table.project(:account_id).distinct,
        Profile.arel_table.project(:account_id).distinct.where(
          Profile.arel_table[:parent_profile_id].not_eq(nil)
        )
      )
    end

    def accounts_with_hosts
      if ApplicationRecord.connection.data_source_exists?(Host.table_name)
        Host.with_policies_or_test_results.select(:account).distinct.arel
      else
        # When setting up initial migrations and cyndi is not yet available
        ApplicationRecord.none
      end
    end
  end
end
