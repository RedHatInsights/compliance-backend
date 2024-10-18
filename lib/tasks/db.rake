# frozen_string_literal: true

# rubocop:disable Layout/BlockLength
namespace :db do
  desc 'Reindex the database, including the inventory table'
  task reindex: [:environment] do
    query = <<-SQL
      DO $$
      DECLARE
          tbl RECORD;
      BEGIN
          FOR tbl IN SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'inventory' LOOP
              EXECUTE format('VACUUM ANALYZE %I.%I', 'inventory', tbl.tablename);
              EXECUTE format('REINDEX TABLE %I.%I', 'inventory', tbl.tablename);
          END LOOP;

          REINDEX TABLE CONCURRENTLY #{tablename};
          VACUUM ANALYZE #{tablename};

          VACUUM ANALYZE policies;
          VACUUM ANALYZE test_results;
          VACUUM ANALYZE rule_results;
          VACUUM ANALYZE policy_hosts;
          VACUUM ANALYZE profile_rules;
      END $$;
    SQL

    db_config = ActiveRecord::Base.connection_db_config.instance_variable_get(:@configuration_hash)
    conn = PG.connect(dbname: db_config[:database], host: db_config[:host], port: db_config[:port],
                      user: db_config[:username], password: db_config[:password],
                      sslmode: db_config[:sslmode] || 'prefer', sslrootcert: db_config[:sslrootcert])

    conn.exec(query)
  end
end
# rubocop:enable Layout/BlockLength
