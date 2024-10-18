# frozen_string_literal: true

namespace :db do
  desc 'Reindex the database, including the inventory table'
  task reindex: [:environment] do
    tablename = ActiveRecord::Base.connection.exec_query(
      "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'inventory';"
    ).rows.first

    query = <<-SQL
      REINDEX TABLE CONCURRENTLY #{tablename};
      VACUUM ANALYZE #{tablename};

      VACUUM ANALYZE policies;
      VACUUM ANALYZE test_results;
      VACUUM ANALYZE rule_results;
      VACUUM ANALYZE policy_hosts;
      VACUUM ANALYZE profile_rules;
    SQL

    ActiveRecord::Base.connection.execute(query)
  end
end
