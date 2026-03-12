# frozen_string_literal: true

module V2
  # Policies for accessing Systems
  class SystemPolicy < V2::ApplicationPolicy
    def index?
      true # FIXME: this is handled in scoping
    end

    def show?
      match_account? && match_workspace?(record)
    end

    def create?
      true
    end

    def update?
      match_account? && match_workspace?(record)
    end

    def destroy?
      match_account? && match_workspace?(record)
    end

    def os_versions?
      true
    end

    private

    def match_account?
      record.org_id == user.org_id
    end

    # Only show systems in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        user.cert_authenticated? ? resolve_cert_auth : resolve_regular
      end

      # In aggregations, we should not join with all systems, so scoping them `org_id`
      def aggregate
        base_scope
      end

      private

      def resolve_regular
        groups = user.inventory_groups

        # No access to systems if there is no org_id or any RBAC (group) rule available
        return scope.none if user.org_id.blank? || groups.blank?

        # Apply inventory group rules on the query if needed
        return base_scope if groups == Rbac::ANY

        return with_groups_via_temp_table(base_scope, groups) if requires_temp_table(groups)

        base_scope.with_groups(groups)
      end

      def requires_temp_table(groups)
        KesselRbac.enabled? && groups.length > KesselRbac.groups_temp_table_threshold
      end

      def resolve_cert_auth
        base_scope.where(V2::System::OWNER_ID.eq(user.system_owner_id))
      end

      def base_scope
        scope.where(org_id: user.org_id)
      end

      # Optimized approach for large group lists using temporary tables
      def with_groups_via_temp_table(filtered_scope, groups)
        conn = filtered_scope.connection
        table_name = "temp_user_groups_#{SecureRandom.hex(8)}"
        begin
          create_temp_table(conn, table_name)
          fill_temp_table(conn, table_name, groups)
          find_in_temp_table(conn, filtered_scope, table_name)
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.error("Temp table optimization failed, falling back to standard approach: #{e.message}")
          filtered_scope.with_groups(groups)
        end
      end

      def create_temp_table(conn, table_name)
        conn.execute(<<~SQL)
          CREATE TEMP TABLE #{conn.quote_table_name(table_name)} (
            group_jsonb jsonb PRIMARY KEY
          ) ON COMMIT DROP
        SQL
      end

      def fill_temp_table(conn, table_name, groups)
        group_array = groups.map { |g| conn.quote(g) }.join(',')
        conn.execute(<<~SQL)
          INSERT INTO #{conn.quote_table_name(table_name)} (group_jsonb)
          SELECT jsonb_build_array(jsonb_build_object('id', group_id))
          FROM unnest(ARRAY[#{group_array}]) AS group_id
          ON CONFLICT (group_jsonb) DO NOTHING
        SQL
      end

      def find_in_temp_table(scope, table_name)
        scope.where(<<~SQL)
          EXISTS (
            SELECT 1 FROM #{ActiveRecord::Base.connection.quote_table_name(table_name)} ug
            WHERE inventory.hosts.groups @> ug.group_jsonb
          )
        SQL
      end
    end
  end
end
