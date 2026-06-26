#!/usr/bin/bash

MAX_INIT_TIMEOUT_SECONDS=${MAX_INIT_TIMEOUT_SECONDS:-120}

for ((i=1;i<=MAX_INIT_TIMEOUT_SECONDS;i++)); do
    # Check if DB is pre-populated by verifying schema_migrations table
    DB_STATE=$(bundle exec ruby -e "
      begin
        require 'active_record'
        ActiveRecord::Base.establish_connection
        if ActiveRecord::Base.connection.table_exists?('schema_migrations')
          puts '[DB_STATE_CHECK] PRE_POPULATED_DB'
        else
          puts '[DB_STATE_CHECK] FRESH_DB'
        end
      rescue StandardError => e
        puts '[DB_STATE_CHECK] PENDING_CONNECTION'
      end
    " 2>/dev/null)

    echo "$DB_STATE"

    if [[ "$DB_STATE" != "[DB_STATE_CHECK] PENDING_CONNECTION" ]]; then
        if bundle exec rake --trace db:debug db:migrate ssg:check_synced; then
            exit 0
        fi
    fi
    sleep 1
done

exit 1
